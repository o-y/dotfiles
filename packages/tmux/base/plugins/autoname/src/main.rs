use clap::Parser;

mod parser;
mod retriever;
mod validator;

#[derive(Parser, Debug, PartialEq, Eq)]
#[command(version, about, long_about = None)]
pub struct Args {
    #[arg(
        short = 'p',
        long,
        help = "Name of the currently running process (e.g. zsh, cargo, nvim, gradle, etc.)"
    )]
    pub process_name: String,

    #[arg(
        short = 'd',
        long,
        help = "The current working directory of the pane",
    )]
    pub working_directory: String,

    #[arg(
        short = 'c',
        long,
        help = "The number of panes open in the current window",
        default_value_t = 1
    )]
    pub pane_count: u8,

    #[arg(
        short = 'r',
        long,
        help = "Defines what metadata should be retrieved given the process name and directory, valid values are: 'tab_colour', 'tab_icon' and 'tab_name'.",
    )]
    pub retrieve: String,
}

fn main() {
    let args = Args::parse();

    if let Err(e) = validator::validate_args(&args) {
        eprintln!("[autoname] validation Error: {}", e);
        std::process::exit(1);
    }

    match parser::parse_autoname_config() {
        Ok(app_config) => {
            let tab_appearance = retriever::compute_tab_appearance(
                &args.process_name,
                &args.working_directory,
                &app_config,
            );

            let output_value = match args.retrieve.as_str() {
                "tab_icon" => tab_appearance.icon + " ",
                "tab_name" => tab_appearance.name,
                "tab_colour" => tab_appearance.colour,
                _ => unreachable!(),
            };
            println!("{}", output_value);
        }
        Err(e) => {
            eprintln!("[autoname] error loading configuration: {}", e);
            std::process::exit(1);
        }
    }
}