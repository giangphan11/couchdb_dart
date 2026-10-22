import '../responses/design_documents_response.dart';

/// Only provided for backward compatibility
@Deprecated('Use DesignDocumentsResponse instead')
class DesignDocumentModelResponse extends DesignDocumentsResponse {
  DesignDocumentModelResponse.from(super.response) : super.from();

  DesignDocumentModelResponse({
    super.ddoc,
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
    super.name,
    super.viewIndex,
    super.offset,
    super.rows,
    super.totalRows,
    super.updateSeq,
    super.results,
    super.status,
    super.raw,
  });
}
