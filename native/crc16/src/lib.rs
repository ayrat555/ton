use rustler::{Binary, NifResult};

const POLY: i32 = 0x1021;
const MASK: i32 = 0x80;
const FFFF: i32 = 0xffff;

#[rustler::nif]
fn do_calc<'a>(payload: Binary<'a>) -> NifResult<i32> {
    let mut extended_payload: Vec<u8> = vec![];
    extended_payload.extend_from_slice(payload.as_slice());
    extended_payload.append(&mut vec![0, 0]);

    let mut reg: i32 = 0;
    for payload_byte in extended_payload {
        let mut mask = MASK;

        while mask > 0 {
            reg = reg << 1;

            if ((payload_byte as i32) & mask) > 0 {
                reg = reg + 1;
            }

            mask = mask >> 1;

            if reg > FFFF {
                reg = reg & FFFF;
                reg = reg ^ POLY;
            }
        }
    }

    Ok(reg)
}

rustler::init!("Elixir.Ton.Crc16", [do_calc]);
