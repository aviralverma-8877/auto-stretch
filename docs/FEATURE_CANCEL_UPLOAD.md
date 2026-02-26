# Feature: Cancel Upload

## Overview

Users can now cancel an in-progress file upload with a single click. This provides full control over the upload process and allows users to abort uploads that are taking too long or were started by mistake.

## User Experience

### During Upload

When a file is being uploaded, the progress section shows:

```
📤 Uploading...

[████████████░░░░░░░░] 65%

65%        12.34 MB/s        136.85 / 210.94 MB

📱 Screen staying awake

[❌ Cancel Upload]
```

### After Cancellation

When user clicks "Cancel Upload":
1. Upload is immediately aborted
2. Progress bar disappears
3. Wake lock released (if on mobile)
4. File selection re-enabled
5. Message shown: "Upload canceled by user"

## Implementation

### Frontend Changes

#### 1. **Cancel Button HTML** ([src/templates/index.html](src/templates/index.html))

Added cancel button in upload progress section:
```html
<div style="margin-top: 20px; text-align: center;">
    <button type="button" class="btn btn-danger" id="cancelUploadBtn" onclick="cancelUpload()">
        ❌ Cancel Upload
    </button>
</div>
```

#### 2. **JavaScript Variables**

Track current upload request:
```javascript
let currentUploadXHR = null;  // Current upload request (for cancellation)
```

#### 3. **Cancel Function**

Handles the abort process:
```javascript
function cancelUpload() {
    if (currentUploadXHR) {
        console.log('Canceling upload...');

        // Abort the XHR request
        currentUploadXHR.abort();
        currentUploadXHR = null;

        // Release wake lock
        releaseWakeLock();

        // Re-enable file upload
        enableFileUpload();

        // Hide upload progress
        document.getElementById('uploadProgressSection').style.display = 'none';

        // Show parameters section if file was selected
        if (selectedFile) {
            parametersSection.style.display = 'block';
        }

        // Show cancellation message
        showError('Upload canceled by user');
    }
}
```

#### 4. **Store XHR Reference**

When upload starts:
```javascript
const xhr = new XMLHttpRequest();
currentUploadXHR = xhr;  // Store for cancellation
```

#### 5. **Clear Reference**

When upload completes/errors/aborts:
```javascript
xhr.addEventListener('load', function() {
    currentUploadXHR = null;  // Clear reference
    // ... rest of handler
});

xhr.addEventListener('error', function() {
    currentUploadXHR = null;  // Clear reference
    // ... rest of handler
});

xhr.addEventListener('abort', function() {
    currentUploadXHR = null;  // Clear reference
    console.log('Upload aborted by user');
});
```

### CSS Styling

#### **Danger Button** ([src/static/css/style.css](src/static/css/style.css))

Red gradient button for cancel action:
```css
.btn-danger {
    background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
    color: white;
    border: 1px solid rgba(239, 68, 68, 0.5);
}

.btn-danger:hover {
    background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
    box-shadow:
        0 8px 25px rgba(0, 0, 0, 0.5),
        0 0 30px rgba(239, 68, 68, 0.5);
}
```

## How It Works

### 1. **User Starts Upload**
- File is selected and "Auto Stretch" is clicked
- XHR request starts
- Reference stored in `currentUploadXHR`
- Progress bar and cancel button appear

### 2. **User Clicks Cancel**
- `cancelUpload()` function called
- XHR request aborted via `xhr.abort()`
- Network connection terminated
- Resources cleaned up

### 3. **Cleanup Process**
- Wake lock released (mobile)
- File upload button re-enabled
- Progress bar hidden
- Parameters section shown
- Error message displayed

### 4. **Ready for Next Upload**
- User can immediately select a new file
- No need to refresh page
- All state properly reset

## Technical Details

### XMLHttpRequest.abort()

The `abort()` method:
- Immediately terminates the HTTP request
- Triggers the `abort` event
- Prevents further `progress` events
- Safe to call at any time
- No partial data is saved

### Event Flow

```
User clicks cancel
    ↓
cancelUpload() called
    ↓
xhr.abort() executed
    ↓
'abort' event fired
    ↓
currentUploadXHR = null
    ↓
UI cleanup performed
    ↓
Ready for new upload
```

### State Management

| State | currentUploadXHR | UI State | Upload Button |
|-------|------------------|----------|---------------|
| **Idle** | null | Normal | Enabled |
| **Uploading** | XHR object | Progress bar | Disabled |
| **Canceled** | null | Error message | Enabled |
| **Completed** | null | Results | Enabled |
| **Error** | null | Error message | Enabled |

## Browser Compatibility

✅ **XMLHttpRequest.abort()** is supported in all browsers:
- Chrome (all versions)
- Firefox (all versions)
- Safari (all versions)
- Edge (all versions)
- Opera (all versions)
- Mobile browsers (all)

## Use Cases

### 1. **Wrong File Selected**
User realizes they selected the wrong file after upload starts.
- Click cancel
- Select correct file
- Upload again

### 2. **Upload Taking Too Long**
Network is slow and upload is taking minutes.
- Click cancel
- Try again later
- Or compress file first

### 3. **Network Issues**
Connection is unstable causing slow upload.
- Click cancel
- Switch to better network
- Retry upload

### 4. **Changed Mind**
User decides not to process this image.
- Click cancel
- Select different file
- Or close browser

### 5. **Phone Interruption**
Incoming call or urgent notification on mobile.
- Click cancel
- Handle interruption
- Return and upload again later

## Benefits

### For Users
✅ **Full Control** - Can stop upload anytime
✅ **No Wasted Time** - Don't wait for wrong upload to finish
✅ **Better UX** - Feels responsive and controllable
✅ **Clean State** - Proper cleanup, ready for next action
✅ **No Refresh Needed** - Can retry immediately

### For System
✅ **Resource Cleanup** - Releases network connections
✅ **Wake Lock Release** - Saves battery on mobile
✅ **Memory Management** - Frees upload buffers
✅ **Server Load** - Reduces unnecessary processing
✅ **Bandwidth** - Stops consuming network resources

## Error Handling

### Scenarios

**1. Cancel During Upload:**
```
Status: Aborted
Message: "Upload canceled by user"
Action: Show error section, re-enable upload
```

**2. Cancel After Completion:**
```
Status: No effect (upload already done)
Action: currentUploadXHR is null, nothing happens
```

**3. Network Drops During Cancel:**
```
Status: Aborted + Network error
Action: Both events fire, cleanup happens once
```

## Testing

### Manual Testing

1. **Basic Cancel:**
   - Upload large file
   - Click cancel at 50%
   - Verify: Progress stops, upload button enabled

2. **Quick Cancel:**
   - Upload file
   - Immediately click cancel
   - Verify: Properly aborted, no errors

3. **Late Cancel:**
   - Upload small file (fast upload)
   - Try to cancel near 100%
   - Verify: Either cancels or completes cleanly

4. **Mobile Test:**
   - Upload on phone
   - Verify wake lock released when canceled
   - Check battery/power settings

5. **Retry After Cancel:**
   - Upload file
   - Cancel midway
   - Select same file
   - Upload again
   - Verify: Works correctly

### Edge Cases

- ✅ Cancel when progress is at 0%
- ✅ Cancel when progress is at 99%
- ✅ Multiple rapid cancel clicks
- ✅ Cancel during network timeout
- ✅ Cancel with wake lock active
- ✅ Cancel and immediate new upload

## Future Enhancements

Possible improvements:
- [ ] Pause/resume upload instead of cancel
- [ ] Show "Canceling..." state briefly
- [ ] Confirm dialog before cancel (optional)
- [ ] Keyboard shortcut (Esc key)
- [ ] Auto-cancel on page unload warning
- [ ] Cancel with cleanup on server side
- [ ] Track cancellation analytics

## Related Features

- **Upload Progress Bar** - Shows real-time progress
- **Wake Lock** - Keeps screen awake during upload
- **Upload Button Disabling** - Prevents duplicate uploads
- **Error Handling** - Displays cancellation message

See:
- [FEATURE_UPLOAD_PROGRESS.md](FEATURE_UPLOAD_PROGRESS.md)
- [FEATURE_WAKE_LOCK.md](FEATURE_WAKE_LOCK.md)

## Status

✅ **Fully Implemented and Tested**

The cancel upload feature is complete and ready for production use. Users now have full control over their uploads with the ability to abort at any time with a single click.

## Files Modified

| File | Changes |
|------|---------|
| `src/templates/index.html` | Added cancel button, cancelUpload() function, XHR tracking |
| `src/static/css/style.css` | Added .btn-danger styles for cancel button |

## Summary

This feature significantly improves user control by:
- Providing immediate abort capability
- Cleaning up all resources properly
- Maintaining clean application state
- Enabling instant retry
- Working seamlessly with other features (wake lock, progress bar)

Perfect for handling large astronomical TIFF files that may take a long time to upload! ❌⏸️
