package examples

import "../../cli"

import "core:strings"
import "core:fmt"
import "core:os"

HELP :: `
=====================================================
This CLI tool does a simple char+1 encryption

Usage:
    examples -input "myfile.txt" -out "out.txt"

Arguments
    -encrypt, -e Perform encryption (default)
    -decrypt, -d Perform decryption 
    -input, -i "filepath" Encrypt this file 
    -out, -o "filepath" Set the output of the encrypted file
=====================================================
`

Converter :: struct {
    input_file: string,
    output_file: string,
    encrypt: bool,
}

process_args :: proc () -> Maybe(Converter) {

    cli.setup(HELP)

    
    defer cli.destroy()

    // declare all possible arguments and good defaults
    cli.declare(
        "input", {"-input", "-i"},
        "The input file to use for processing", 
        "Please provide a file to convert",
        required = true,
        default = nil,
        expected = .String,
    ) 

    cli.declare(
        "output", {"-out", "-o"}, 
        "Set the output file to write", 
        "", 
        required = false, 
        default = "output.tmp",
        expected = .String,
    )

    cli.declare(
        "encrypt", {"-encrypt", "-e"},
        "Perform encryption (default)",
        "",
        required = false,
        default = true,
        expected = .Bool,
    )

    cli.declare(
        "decrypt", {"-decrypt", "-d"},
        "Perform decryption",
        "",
        required = false,
        default = true,
        expected = .Bool,
    )

    cli.declare(
        "help", {"-help"}, 
        "Print the help message", 
        "", 
        required = false, 
        default = nil,
        expected = nil,
    )

    // Collect all the arguments from the command line
    missing, found := cli.collect()

    if found == 0 {
        // no args passed (print usage)
        cli.help()
        return nil
    } else if missing > 0 { 
        // we have missing required parameters
        cli.print_errors()
        return nil
    } 
     

    // only show help if we explicitly asked for it
    show_help := cli.was_declared("help")
    if show_help {
        cli.help()
        return nil
    }
 
    filename := cli.by_name("input")
    if filename == nil {
        return nil
    }

    output := cli.by_name("output", false)
    if output == nil {
        return nil
    }

    encrypting := true
    decrypt := cli.by_name("decrypt", true)
    if decrypt != nil {
        if decrypt.?.value.(bool) == true {
            encrypting = false
        }
    }

    convert := Converter {
        input_file = filename.?.value.(string),
        output_file = output.?.value.(string),
        encrypt = encrypting,
    }

    return convert
}

encrypt_string :: proc (input: []u8) -> []u8 {
    out := input

    for c,i in out {
        out[i] += 1
    }

    return out
}

decrypt_string :: proc (input: []u8) -> []u8 {
    out := transmute([]u8)input

    for c,i in out {
        out[i] -= 1
    }

    return out
}

main :: proc () { 
    convert, ok := process_args().?; if ok {
        fmt.printfln("Converting {} to {}", convert.input_file, convert.output_file)
        
        data, ok := os.read_entire_file_from_filename(convert.input_file)
        if !ok {
            fmt.printfln("Unable to load file ({})", convert.input_file)
            return
        }
        defer delete(data)


        if convert.encrypt {
            fmt.print("Encrypting...")
            output := encrypt_string(data[:])
            success := os.write_entire_file(convert.output_file, output[:])
            if !success {
                fmt.printfln("Unable to write to file ({})", convert.output_file)
                return
            }
        } else {
            fmt.print("Decrypting...")
            output := decrypt_string(data[:])
            success := os.write_entire_file(convert.output_file, output[:])
            if !success {
                fmt.printfln("Unable to write to file ({})", convert.output_file)
                return
            }
        }
  
        
        fmt.printfln("File ({}) has been written to ({}).", 
            convert.input_file, 
            convert.output_file)

    } 
}