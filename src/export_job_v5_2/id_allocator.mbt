///|
/// Deterministic ID allocator (v5.2).
/// Shared across single and batch job families.

let counter : Ref[Int] = @ref.new(0)

///|
pub fn reset_id_for_test() -> Unit {
  counter.val = 0
}

///|
pub fn seed_id_for_test(next_id : Int) -> Unit {
  counter.val = next_id
}

///|
pub fn next_job_id() -> JobId {
  counter.val = counter.val + 1
  { value: "job-" + counter.val.to_string() }
}
