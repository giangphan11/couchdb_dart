import '../responses/documents_response.dart';

/// Only provided for backward compatibility
@Deprecated('Use DocumentsResponse instead')
class DocumentModelResponse extends DocumentsResponse {
  DocumentModelResponse.from(super.response) : super.from();

  DocumentModelResponse({
    super.doc,
    super.ok,
    super.id,
    super.rev,
    super.attachment,
    super.conflicts,
    super.deleted,
    super.deletedConflicts,
    super.localSeq,
    super.revsInfo,
    super.revisions,
  });
}
