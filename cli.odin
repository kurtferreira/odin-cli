// A simple library to make working with CLI arguments easier
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
    parsed_from_cli: bool, 
    expects: Type,
    value: union {
        f64, 
        bool, 
        string
    },
    value_str: string
}

@(private)
Cli :: struct {
    args: [dynamic] Arg,
    help: string,
    errors: [dynamic] string
} 

@(private)
cli := Cli {}

@(private)
index_name :: proc (name: string) -> int {
    for arg, i in cli.args {
        if arg.name == name {
            return i
        }
    }

    return -1
}

@(private)
index_alias :: proc (name: string) -> int {
    for arg, i in cli.args {
        for alias in arg.aliases {
            if alias == name {
                return i
            }
        } 
    }
    return -1
}

// Was an argument declared via the CLI
was_declared :: proc (name: string) -> bool {
    arg, ok := by_name(name).?; if ok {
        return arg.parsed_from_cli
    }

    return false
}

// Declare a new anticipated argument
declare :: proc (name: string, aliases: []string, description: string, help: string, required: bool, default: union {f64, bool, string}, expected: Type) {
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
        parsed_from_cli = false,
        expects = expected,
        value_str = fmt.aprintf("{}", default),
        value = default,
    } 

    append(&cli.args, arg)
}

// Collect the arguments from the command line
// Will print out the missing fields if any
collect :: proc() -> (missing: int = 0, found: int = 0) {
    arg := 1
    for i in 1..<len(os.args) {

        if arg >= len(os.args) { 
            break 
        }

        pos := index_alias(os.args[arg]); if pos != -1 {
            cli.args[pos].parsed_from_cli = true
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
                    exists := index_alias(next); if exists != -1 {
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

    for a in cli.args {
        if !a.parsed_from_cli && a.required {
            missing += 1
            append(&cli.errors, fmt.aprintf("{}", a.help))
        }
    }

    return missing, found
}

// Print any missing arguments
print_errors :: proc() {
    fmt.printfln("{}", strings.concatenate(cli.errors[:]))
}

// Setup the CLI context with a custom user help message
setup :: proc (help: string) {
    cli.help = help
    cli.args = {}
}

// Free any allocated resources
destroy :: proc() { 
    delete(cli.args)
    delete(cli.errors)
}

// Retrieve an argument by its name
by_name :: proc(name: string, must_parsed: bool = true) -> Maybe(Arg) {
    for arg in cli.args {
        if arg.name == name {
            return arg if !must_parsed || (must_parsed && arg.parsed_from_cli) || (!arg.required && !must_parsed) else nil
        }
    }

    return nil
}

// Retrieve an argument by its alias (e.g. -f or -file)
by_alias :: proc (name: string, must_parsed: bool = true) -> Maybe(Arg) {
    for arg in cli.args {
        for alias in arg.aliases {
            if alias == name {
                return arg if !must_parsed || (must_parsed && arg.parsed_from_cli) || (!arg.required && !must_parsed) else nil
            }
        } 
    }

    return nil
}

// Print the user's help message
help :: proc() {
    fmt.printfln("{}", cli.help)
}