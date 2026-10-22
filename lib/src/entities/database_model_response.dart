import '../responses/databases_response.dart';

/// Only provided for backward compatibility
@Deprecated('Use DatabasesResponse instead')
class DatabaseModelResponse extends DatabasesResponse {
  DatabaseModelResponse.from(super.response) : super.from();

  DatabaseModelResponse({
    super.cluster,
    super.compactRunning,
    super.dbName,
    super.diskFormatVersion,
    super.docCount,
    super.docDelCount,
    super.purgeSeq,
    super.sizes,
    super.updateSeq,
    super.ok,
    super.id,
    super.rev,
    super.offset,
    super.rows,
    super.totalRows,
    super.results,
    super.docs,
    super.warning,
    super.executionStats,
    super.bookmark,
    super.result,
    super.name,
    super.indexes,
    super.index,
    super.selector,
    super.opts,
    super.limit,
    super.skip,
    super.fields,
    super.range,
    super.lastSeq,
    super.pending,
    super.admins,
    super.members,
    super.purged,
    super.missedRevs,
    super.revsDiff,
    super.list,
    super.shards,
    super.shardRange,
    super.nodes,
  });
}
