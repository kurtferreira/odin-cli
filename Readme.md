# Odin Command Line Interface Library

Simple CLI utility library that makes working with CLI args a bit easier.

## Usage

```odin
import "lib:cli" // change to whatever folder you use

main :: proc () {
    // Set up the help message
    ctx := cli.setup(`
=====================================================
My awesome CLI tool
This CLI tool does some crazy CLI parsing

Usage:
    tool -file "my file"

Arguments
    -file "filepath" Take in an argument with name 'file' and value 'filepath'
    
=====================================================
    `)
    defer cli.destroy(&ctx)

    // declare all possible arguments and good defaults
    cli.declare(&ctx,
        "file",
        {"-file", "-f"},
        "The input file to use for processing", 
        "Please provide a file to convert",
        required = true,
        default = nil,
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

    if found == 0 {
        // no args passed (print usage)
        cli.help(&ctx)
        return
    } else if missing > 0 { 
        cli.print_errors(&ctx)
        return
    } 
    
    // only show help if we explicitly asked for it
    show_help := cli.by_name(&ctx, "help"); if show_help != nil {
        cli.help(&ctx)
        return
    }
    
    // Get the filename that we want to convert
    filename, ok := cli.by_name(&ctx, "file").?; if ok {
        fmt.printfln("Convert file {}", filename.value)
    }
}

```