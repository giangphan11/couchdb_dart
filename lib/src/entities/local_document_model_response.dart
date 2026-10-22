import '../responses/local_documents_response.dart';

/// Only provided for backward compatibility
@Deprecated('Use LocalDocumentsResponse instead')
class LocalDocumentModelResponse extends LocalDocumentsResponse {
  LocalDocumentModelResponse.from(super.response) : super.from();

  LocalDocumentModelResponse({
    super.offset,
    super.rows,
    super.totalRows,
    super.updateSeq,
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
