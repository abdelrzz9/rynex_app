sealed class Failure {
  const Failure();
}

class StorageFailure extends Failure {
  final String message;
  const StorageFailure(this.message);
}

class ImportFailure extends Failure {
  final String message;
  const ImportFailure(this.message);
}

class ExportFailure extends Failure {
  final String message;
  const ExportFailure(this.message);
}

class ProjectNotFoundFailure extends Failure {
  final String projectId;
  const ProjectNotFoundFailure(this.projectId);
}

class UnsupportedFormatFailure extends Failure {
  final String format;
  const UnsupportedFormatFailure(this.format);
}
