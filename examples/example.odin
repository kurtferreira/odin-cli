package examples

import "../../cli"

import "core:fmt"
import "core:os"

HELP :: `
=====================================================
This CLI tool does a simple char+1 encryption

Usage:
    examples -input "myfile.txt" -out "out.txt"

Arguments
    -input, -i "filepath" Encrypt this file 
    -out, -o "filepath" Set the output of the encrypted file
=====================================================
`

Converter :: struct {
    input_file: string,
    output_file: string
}

process_args :: proc () -> Maybe(Converter) {
    ctx := cli.setup(HELP)
    defer cli.destroy(&ctx)

    // declare all possible arguments and good defaults
    cli.declare(&ctx,
        "input",
        {"-input", "-i"},
        "The input file to use for processing", 
        "Please provide a file to convert",
        required = true,
        default = nil,
        expected = .String,
    ) 

    cli.declare(&ctx, 
        "output",
        {"-out", "-o"}, 
        "Set the output file to write", 
        "", 
        required = false, 
        default = "output.tmp",
        expected = .String,
    )

    cli.declare(&ctx, 
        "help",
        {"-help"}, 
        "Print the help message", 
        "", 
        required = false, 
        default = nil,
        expected = nil,
    )

    // Collect all the arguments from the command line
    missing, found := cli.collect(&ctx)


    if found == 0 && missing == 0 {
        // no args passed (print usage)
        cli.help(&ctx)
        return nil
    } else if missing > 0 { 
        cli.print_errors(&ctx)
        return nil
    } 
    
    // only show help if we explicitly asked for it
    show_help := cli.by_name(&ctx, "help"); if show_help != nil {
        cli.help(&ctx)
        return nil
    }
    
    filename, ok_in := cli.by_name(&ctx, "input").?; if !ok_in {
        return nil
    }

    output, ok_out := cli.by_name(&ctx, "output", false).?; if !ok_out {
        return nil
    }

    convert := Converter {
        input_file = filename.value.(string),
        output_file = output.value.(string)
    }

    return convert
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

        // simple character shit encoding
        for c,i in data {
            data[i] = c + 1
        }

        success := os.write_entire_file(convert.output_file, data[:])
        if !success {
            fmt.printfln("Unable to write to file ({})", convert.output_file)
            return
        }
        
        fmt.printfln("File ({}) has been encoded to ({}).", 
            convert.input_file, 
            convert.output_file)

    } 
}