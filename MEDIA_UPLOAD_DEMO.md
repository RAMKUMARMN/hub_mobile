# Camera & Voice Media Upload — Demo Document

> Demo guide for the **Media** feature: capturing voice / photo / video on the
> phone and uploading it to Amazon S3 through a presign **AWS Lambda** Function
> URL. This document describes the workflow, the exact Lambda request/response
> contract, and a step-by-step demo script.

---

## 1. Purpose (the "why")

- **Capture-first, offline-resilient.** Every voice note, photo and video is
  written to the phone's local storage **before** any network call, then queued.
- **No AWS credentials in the app.** The app asks a Lambda Function URL for a
  short-lived **presigned URL**, then uploads the bytes straight to S3.
- **Self-healing uploads.** Files that fail to upload are retried automatically
  (in-app timer every 2 minutes, on app-resume, and via OS background tasks).
- **Large-file ready.** Small files use a single presigned `PUT`; files larger
  than **100 MiB** use **S3 multipart upload** in chunks.

---

## 2. High-level architecture

```
┌─────────────────────────── Phone (Flutter app) ───────────────────────────┐
│                                                                           │
│  Media tab                                                                │
│   ├─ Voice  ─────► record mic (record plugin)                             │
│   ├─ Photo  ─────► native camera (image_picker)                           │
│   └─ Video  ─────► native camera (image_picker)                           │
│                          │                                                │
│                          ▼                                                │
│             Save file locally + enqueue (MediaStore / media_queue.json)   │
│                          │                                                │
│                          ▼                                                │
│             MediaUploader.syncPending()                                   │
│                          │                                                │
│        ┌─────────────────┴─────────────────┐                              │
│        │ 1. POST presign request            │  (no AWS creds)             │
│        ▼                                    ▼                              │
│   Lambda Function URL ──► returns presigned URL(s)                        │
│        │                                                                  │
│        │ 2. PUT file bytes directly to S3                                 │
│        ▼                                                                  │
└────────┼──────────────────────────────────────────────────────────────────┘
         ▼
   Amazon S3 bucket: cixio-hub (ap-south-1)
   Key prefix: testing/user1/
```

**Key components**

| Layer | File | Responsibility |
|---|---|---|
| UI | `lib/screens/media/media_screen.dart` | Voice/Photo/Video buttons, live status list |
| Service | `lib/services/media_service.dart` | Capture, local save, enqueue, retry timer |
| Queue | `lib/services/media_store.dart` | Durable JSON queue + `media/` folder |
| Uploader | `lib/services/media_uploader.dart` | Orchestrates upload of pending items |
| S3 client | `lib/services/presign_upload_service.dart` | Talks to Lambda + S3 (single & multipart) |
| Notifier | `lib/services/upload_notifier.dart` | Device notification on upload / delete complete or fail |
| Background | `lib/services/background_sync.dart` | WorkManager / BGTaskScheduler retries |
| Config | `lib/config/app_config.dart` | Reads `AWS_UPLOAD_URL` from `.env`/`--dart-define` |

---

## 3. Configuration

The Lambda endpoint is supplied through the bundled `.env` file (or
`--dart-define=AWS_UPLOAD_URL=...`):

```
AWS_UPLOAD_URL=https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/
```

- **Endpoint:** `https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/`
- **Bucket:** `cixio-hub`
- **Region:** `ap-south-1` (Mumbai)
- **Key prefix:** `testing/user1/`
- **Method:** `POST`, `Content-Type: application/json`

An unknown `action` value makes the Lambda reply
`{"error":"Invalid action type specified"}`.

---

## 4. The Lambda contract (what the app sends & receives)

The app talks to the Lambda in up to **three** calls. Small files need only
call #1 + a direct S3 PUT. Large files use all three.

### 4.1 Single upload — get one presigned URL

**App sends**

```http
POST https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/
Content-Type: application/json

{
  "fileName": "demo.jpg",
  "mimeType": "image/jpeg"
}
```

**Lambda responds**

```json
{
  "mode": "SINGLE",
  "presignedUrl": "https://cixio-hub.s3.ap-south-1.amazonaws.com/testing/user1/1792041204870-demo.jpg?X-Amz-Algorithm=...&X-Amz-Signature=...",
  "objectKey": "testing/user1/1792041204870-demo.jpg",
  "mimeType": "image/jpeg"
}
```

**Then the app** does a direct HTTP `PUT` of the file bytes to `presignedUrl`
(no AWS credentials involved). The S3 object key is `objectKey`.

> Note: the Lambda generates a unique key by prefixing a timestamp
> (`<epoch-ms>-<fileName>`).

---

### 4.2 Multipart — step 1: initiate

Used when the file is larger than `multipartThreshold` (default **100 MiB**).

**App sends**

```http
POST https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/
Content-Type: application/json

{
  "action": "MULTIPART_INITIATE",
  "fileName": "demo.mp4",
  "mimeType": "video/mp4",
  "size": 15728640,
  "totalParts": 2
}
```

- `size` — total file size in bytes.
- `totalParts` — how many chunks the app wants (the Lambda returns one presigned
  URL per part).

**Lambda responds**

```json
{
  "mode": "MULTIPART",
  "uploadId": "wl.33qGOFM7iF8GBBshBEVk972QAxcm2.9WbA4FE...",
  "objectKey": "testing/user1/1792041209378-demo.mp4",
  "parts": [
    {
      "partNumber": 1,
      "url": "https://cixio-hub.s3.ap-south-1.amazonaws.com/testing/user1/1792041209378-demo.mp4?X-Amz-Algorithm=...&partNumber=1&uploadId=wl.33qG...&x-id=UploadPart"
    },
    {
      "partNumber": 2,
      "url": "https://cixio-hub.s3.ap-south-1.amazonaws.com/testing/user1/1792041209378-demo.mp4?X-Amz-Algorithm=...&partNumber=2&uploadId=wl.33qG...&x-id=UploadPart"
    }
  ]
}
```

### 4.3 Multipart — step 2: upload each part

**App** `PUT`s each chunk to its matching `url`:

```http
PUT <url for partNumber 1>   (bytes 0 .. 10 MiB-1)
PUT <url for partNumber 2>   (remaining bytes)
```

**S3 responds** `200 OK` with an `ETag` response header per part:

```
ETag: "8acbe32feb9842ecc84b84d967ebb7f8"
```

The app collects `{partNumber, ETag}` for every part.

### 4.4 Multipart — step 3: complete

**App sends** (note the **capitalised** `PartNumber` / `ETag` — required)

```http
POST https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/
Content-Type: application/json

{
  "action": "MULTIPART_COMPLETE",
  "uploadId": "wl.33qGOFM7iF8GBBshBEVk972QAxcm2.9WbA4FE...",
  "objectKey": "testing/user1/1792041209378-demo.mp4",
  "parts": [
    { "PartNumber": 1, "ETag": "\"8acbe32feb9842ecc84b84d967ebb7f8\"" },
    { "PartNumber": 2, "ETag": "\"41cb1d65978992627f27c958347c10c9\"" }
  ]
}
```

**Lambda responds**

```json
{
  "message": "Multipart upload completed",
  "location": "https://cixio-hub.s3.ap-south-1.amazonaws.com/testing%2Fuser1%2F1792041209378-demo.mp4"
}
```

### 4.5 Delete object

When the user deletes an uploaded media item, the app asks the Lambda to remove
the S3 object **before** touching local storage.

**App sends**

```http
POST https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/
Content-Type: application/json

{
  "action": "DELETE",
  "objectKey": "testing/user1/1792067214667-to-delete.bin"
}
```

**Lambda** issues `DeleteObjectCommand` to S3 and **responds**

```json
{
  "message": "Object deleted successfully",
  "objectKey": "testing/user1/1792067214667-to-delete.bin"
}
```

- HTTP **200** confirms the object is gone (S3 `DeleteObject` is idempotent, so
  deleting a missing key still returns success).
- Only after the 200 does the app remove the local file (`File.delete()`) and the
  queue entry. If the Lambda call fails, the local file is **kept** and an error
  is shown, so nothing is silently orphaned.

### 4.6 Error responses

| Situation | Response |
|---|---|
| Unknown `action` | `{"error":"Invalid action type specified"}` |
| Bad/unauthorised request to S3 during complete | `{"error":"The specified method is not allowed against this resource."}` or an S3 XML `<Error><Code>…</Code><Message>…</Message></Error>` |
| HTTP non-2xx | App throws `PresignUploadException` with the extracted message + status code |

> There is **no abort action** on this Lambda. If a multipart upload fails midway
> the app retries from scratch; orphaned parts are cleaned up by an S3 lifecycle
> rule (recommended).

**Supported actions** (verified against the live Lambda):

| `action` | Purpose |
|---|---|
| *(omitted)* / `SINGLE` | One presigned PUT URL |
| `MULTIPART_INITIATE` | Start a multipart upload; returns per-part presigned URLs |
| `MULTIPART_COMPLETE` | Finalise a multipart upload |
| `DELETE` | Delete an S3 object (`DeleteObjectCommand`) |

---

## 5. What the app stores / shows

Each captured file becomes a `MediaItem` with:

| Field | Meaning |
|---|---|
| `id` | UUID |
| `type` | `voice` / `photo` / `video` |
| `localPath` | path in app storage |
| `fileName` | UUID-based name (e.g. `a1b2….mp4`) |
| `mimeType` | `audio/mp4`, `image/jpeg`, `video/mp4` |
| `sizeBytes` | file size |
| `status` | `pending` → `uploading` → `uploaded` / `failed` |
| `attempts` | number of tries |
| `s3Key` | set after a successful upload |

The Media list shows a coloured status chip per item:
**Uploading** (blue, spinner), **Uploaded** (green), **Pending** (orange),
**Failed/Retry N** (red — long-press for the error).

Retry cadence: in-app timer every **2 minutes**, on **app resume**, and via OS
background tasks (Android WorkManager; iOS BGTaskScheduler on physical devices).

---

## 5b. Upload & delete notifications

The app posts a **device notification** for upload and delete lifecycle events,
so the user is informed even when the app is backgrounded.

| Event | Title | Body | Fired from |
|---|---|---|---|
| ≥1 file uploaded | `Upload complete` / `Uploads complete` | `N file(s) were uploaded to the cloud.` | `MediaUploader.syncPending()` |
| first-ever failure of ≥1 file | `Upload failed` / `Uploads failed` | `N file(s) could not be uploaded. It will retry automatically.<error>` | `MediaUploader.syncPending()` |
| delete finished **while backgrounded** | `File deleted` | `"<fileName>" was deleted.` | `MediaService.delete()` |
| delete failed **while backgrounded** | `Delete failed` | `"<fileName>" could not be deleted.<error>` | `MediaService.delete()` |

Implementation: `lib/services/upload_notifier.dart` (class `UploadNotifier`).
Upload notifications fire from `MediaUploader.syncPending()` (`media_uploader.dart`);
delete notifications fire from `MediaService.delete()` (`media_service.dart`).

- **Delete notifications are background-only.** A delete is user-initiated from
  the Media screen, so at tap time the app is in the foreground and the screen
  already shows a success/error snackbar. If the app is backgrounded while the
  delete is in flight, `MediaService` (a `WidgetsBindingObserver`) notices and
  posts a notification instead — so the outcome is never missed.

- **Local, not remote.** The upload outcome is known on the device, so no FCM/APNs
  server round-trip is needed — `UploadNotifier` uses the same
  `flutter_local_notifications` plugin that renders foreground push banners.
- **Channel:** `upload_status_channel` ("Upload status"), high importance, sound +
  vibration (same look as the existing foreground push banner).
- **De-duplicated:** fixed notification ids mean a newer result *replaces* the
  previous banner. Failure alerts fire **only on the first failure** (attempts == 1)
  so the 2-minute retry timer doesn't spam the user.
- **Works in both isolates:** the foreground sync (timer / resume / capture) and
  the OS background task both call `syncPending()`, so notifications appear either
  way. All plugin access is guarded and errors are swallowed.
- **Permissions:** requested at app start by `NotificationService.initialize()`
  (`POST_NOTIFICATIONS` is declared in the Android manifest; iOS prompts on
  first launch). `UploadNotifier` never re-prompts.

> True **remote** push (a notification sent from the backend) would require the
> Lambda/backend to call FCM/APNs after the S3 event. That's out of scope for the
> app and is **not** used here.

---

## 6. Demo script (~2 minutes)

1. **Open the app → Media tab** (3rd in the bottom nav).
   Point at the top banner: *"All files uploaded"* with a green cloud.
2. **Voice** — tap the red **Voice** button → the "Voice note" sheet opens and
   starts recording with a live timer → speak 3–5 s → tap **Stop & save**.
   - Snackbar: *"Voice note saved locally — uploading…"*
   - The new row flips **Pending → Uploading → Uploaded**; the cloud stays green.
3. **Photo** — tap **Photo** → take a shot → watch the same lifecycle.
4. **Video** — tap **Video** → record ~5 s → watch it upload.
5. **Notification** — after the file turns **Uploaded**, a device notification
   appears: *"Upload complete — 1 file was uploaded to the cloud."* To demo the
   failure path, turn on Airplane Mode and capture again: after the first failed
   attempt you get *"Upload failed — 1 file could not be uploaded. It will retry
   automatically."* Turn Airplane Mode off and it uploads on the next retry.
6. **Resilience** — pull down to refresh (or tap **Sync now**) to demonstrate the
   retry mechanism.
7. **Delete** — tap the trash icon → confirm. The app deletes the S3 object via
   the Lambda (`action: "DELETE"`) and only then removes the local copy; the row
   disappears and a *"…deleted."* snackbar appears. (Background the app during
   the delete to instead get a *"File deleted"* notification.)

### Optional: show the Lambda live

With a terminal visible, run the exact calls the app makes:

```bash
# Single
curl -s -X POST "https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"fileName":"demo.jpg","mimeType":"image/jpeg"}'

# Delete
curl -s -X POST "https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"action":"DELETE","objectKey":"testing/user1/<object-key>"}'

# Multipart initiate
curl -s -X POST "https://3yzckdgen2ogld553howb2sj3y0yoisu.lambda-url.ap-south-1.on.aws/" \
  -H "Content-Type: application/json" \
  -d '{"action":"MULTIPART_INITIATE","fileName":"demo.mp4","mimeType":"video/mp4","size":15728640,"totalParts":2}'
```

---

## 7. Talking points

- "The file is written to the phone **first**; uploads never block capture."
- "**No AWS keys** ship in the app — the Lambda issues short-lived presigned URLs."
- "Uploads are **self-healing**: retried every 2 minutes and whenever the app reopens."
- "Large videos use **S3 multipart upload**, so a dropped connection only costs one part, not the whole file."
- "The user gets a **notification** when an upload completes or fails — works even while the app is in the background."
- "Delete reports back too: a snackbar in the foreground, a **notification** if the app is backgrounded."
- "Deleting a file removes it from **S3 as well as the phone** — the app calls the Lambda first and only drops the local copy once S3 confirms."

---

## 8. Caveats / troubleshooting

- **Multipart only triggers above 100 MiB** (`multipartThreshold` in
  `presign_upload_service.dart`). To demonstrate multipart, record a long HD
  video or temporarily lower the threshold (e.g. `5 * 1024 * 1024` when the
  service is built in `media_uploader.dart`).
- **Use a physical device** for the full background story. The iOS Simulator
  skips BGTaskScheduler; foreground upload + timer still work there.
- **Network:** the device must reach the Lambda URL and
  `cixio-hub.s3.ap-south-1.amazonaws.com`.
- **Rebuild after code changes:** the S3 client is pure Dart, so a fresh
  `flutter run` reflects any change (hot restart is enough).
