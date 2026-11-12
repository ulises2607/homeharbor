class BoatPhotoUpload
  class InvalidUpload < StandardError; end

  def self.call(boat, upload)
    unless upload.is_a?(ActionDispatch::Http::UploadedFile) && upload.size.positive? && upload.size <= Boat::MAX_PHOTO_BYTES
      raise InvalidUpload, "Elegí una foto de hasta 5 MB."
    end
    # Inspect bytes, never trust the filename or the browser's Content-Type.
    content_type = Marcel::MimeType.for(upload.tempfile)
    raise InvalidUpload, "Usá una imagen JPEG, PNG o WebP." unless Boat::PHOTO_TYPES.include?(content_type)
    upload.tempfile.rewind

    blob = nil
    attached = false
    boat.with_lock do
      raise InvalidUpload, "Cada bote admite hasta #{Boat::MAX_PHOTOS} fotos." if boat.photos.count >= Boat::MAX_PHOTOS
      blob = ActiveStorage::Blob.build_after_unfurling(
        io: upload.tempfile, filename: upload.original_filename, content_type: content_type,
        identify: false, metadata: { analyzed: true }
      )
      blob.save!
      blob.upload_without_unfurling(upload.tempfile)
      boat.photos.attach(blob)
    end
    attached = true
    boat.reload.public_details
  ensure
    # SQL rolls back on failure; remove any partially written object as well.
    if blob && !attached
      begin
        blob.service.delete(blob.key)
      rescue ActiveStorage::Error, IOError, SystemCallError => cleanup_error
        Rails.logger.error("Photo upload cleanup failed: #{cleanup_error.class}")
      end
    end
  end
end
