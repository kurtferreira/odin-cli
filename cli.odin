package cli 

import "core:testing"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Type :: enum {
    Bool,
    String,
    Number,
    None,
}

Arg :: struct { 
    name: string,
    aliases: []string,
    description: string,
    help: string,
    required: bool,
    parsed: bool, // was this parsed from the CLI or did we provide a default
    expects: Type,
    value: union {
        f64, 
        bool, 
        string
    },
    value_str: string
}

Cli :: struct {
    args: [dynamic] Arg,
    help: string,
    errors: [dynamic] string
} 

declare :: proc (cli: ^Cli, name: string, aliases: []string, description: string, help: string, required: bool, default: union {f64, bool, string}, expected: Type) {
    // fixme: why is this failing?
    // #assert(type_of(default) == type_of(expected))
    
    if type_of(default) == type_of(expected) {
        panic("default type and expected type must match")
    }

    arg := Arg {
        name = name,
        aliases = aliases,
        description = description,
        help = help,
        required = required,
        parsed = false,
        expects = expected,
        value_str = "",
        value = default,
    } 

    append(&cli.args, arg)
}

/// Collect the arguments from the command line
/// Will print out the missing fields if any
collect :: proc(cli: ^Cli) -> (missing: int = 0, found: int = 0) {
    arg := 1
    for i in 1..<len(os.args) {

        if arg >= len(os.args) { 
            break 
        }

        pos := index_alias(cli, os.args[arg]); if pos != -1 {
            cli.args[pos].parsed = true
            found += 1

            if cli.args[pos].expects != nil {
                arg += 1

                if arg >= len(os.args) {
                    append(&cli.errors, fmt.aprintf("{}", cli.args[pos].help))

                    missing += 1 
                    return missing, found
                } else {
                    next := os.args[arg]
                    
                    // does the next parameter exist as a arg
                    exists := index_alias(cli, next); if exists != -1 {
                        append(&cli.errors, fmt.aprintf("{}", cli.args[pos].help))

                        missing += 1 
                    }
                    
                    #partial switch cli.args[pos].expects {
                        case .Bool: {
                            cli.args[pos].value_str = "true" if next == "true" else "false"
                            cli.args[pos].value = true if next == "true" else false
                        }
                        case .Number: {
                            cli.args[pos].value = strconv.atof(next) 
                            cli.args[pos].value_str = next   
                        }
                        case .String: {
                            cli.args[pos].value = next
                            cli.args[pos].value_str = next
                        } 
                    }
                }
            }
        } else {
            // @todo: complain about garbage args?
        }

        arg += 1
    }

    return missing, found
}

print_errors :: proc(cli: ^Cli) {
    fmt.printfln("{}", strings.concatenate(cli.errors[:]))
}

setup :: proc (help: string) -> Cli {
    cli: Cli
    cli.help = help
    cli.args = {}

    return cli
}
/// Free any allocated strings or arguments
destroy :: proc(cli: ^Cli) { 
    delete(cli.args)
    delete(cli.errors)
}

@(private)
index_name :: proc (cli: ^Cli, name: string) -> int {
    for arg, i in cli.args {
        if arg.name == name {
            return i
        }
    }

    return -1
}

@(private)
index_alias :: proc (cli: ^Cli, name: string) -> int {
    for arg, i in cli.args {
        for alias in arg.aliases {
            if alias == name {
                return i
            }
        } 
    }
    return -1
}

by_name :: proc(cli: ^Cli, name: string, must_parsed: bool = true) -> Maybe(Arg) {
    for arg in cli.args {
        if arg.name == name {
            return arg if !must_parsed || (must_parsed && arg.parsed) || (!arg.required && !must_parsed) else nil
        }
    }

    return nil
}

by_alias :: proc (cli: ^Cli, name: string, must_parsed: bool = true) -> Maybe(Arg) {
    for arg in cli.args {
        for alias in arg.aliases {
            if alias == name {
                return arg if !must_parsed || (must_parsed && arg.parsed) || (!arg.required && !must_parsed) else nil
            }
        } 
    }

    return nil
}

help :: proc(cli: ^Cli) {
    fmt.printfln("{}", cli.help)
}