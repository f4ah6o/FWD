///|
/// Minimal YAML AST for v1 parsing.
///|
pub enum YamlValue {
  Null
  Bool(Bool)
  String(String)
  Seq(Array[YamlValue])
  Map(Array[(String, YamlValue)])
}

///|
pub(all) suberror YamlError {
  YamlError(line~ : Int, message~ : String)
}

///|
fn YamlError::new(message : String, line : Int) -> YamlError {
  YamlError::YamlError(line=line, message=message)
}

///|
pub impl Show for YamlError with output(self, logger) {
  match self {
    YamlError::YamlError(line~, message~) => {
      logger
      ..write_string("line ")
      ..write_object(line)
      ..write_string(": ")
      ..write_string(message)
    }
  }
}
