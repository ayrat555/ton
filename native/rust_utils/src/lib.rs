#[rustler::nif]
fn clz32(number: i64) -> u32 {
    (number as i32).leading_zeros()
}

rustler::init!("Elixir.Ton.RustUtils", [clz32]);
