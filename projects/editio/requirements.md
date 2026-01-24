# Technical Specifications

## System Architecture

### Core Architecture
- **Language**: Rust (performance, safety, ecosystem)
- **Architecture**: Modular crate-based system with two-pass compilation
- **Target**: CLI tool with library API for programmatic use

### Workspace Structure
```
editio/ (workspace)
├── crates/
│   ├── editio/              # Main CLI binary
│   ├── editio-core/         # Main library (orchestrates everything)
│   ├── editio-ast/          # Shared AST types (used by all renderers)
│   ├── editio-parser/       # Markdown parsing (pulldown-cmark + extensions)
│   ├── editio-layout/       # Layout engine (two-pass, CSS-style floats)
│   ├── editio-render/       # Rendering engine (traits/interfaces)
│   ├── editio-pdf/          # PDF output (printpdf + custom layout)
│   ├── editio-html/         # HTML output (KaTeX math)
│   ├── editio-word/         # Word/DOCX output
│   ├── editio-latex/        # LaTeX output
│   ├── editio-bib/          # Bibliography (BibTeX, BibLaTeX, RIS, EndNote)
│   ├── editio-math/         # Math rendering (pdflatex → Native Rust)
│   ├── editio-template/     # Template system (YAML-based, inheritance)
│   ├── editio-plugin/       # Plugin API crate (stable interface)
│   └── editio-plugin-manager/ # Plugin management (WASM/dylib loading)
```

## Data Models and Structures

### AST (Abstract Syntax Tree)
```rust
pub enum Node {
    Document(Vec<Node>),
    Paragraph(Vec<Inline>),
    Heading { level: u8, content: Vec<Inline> },
    Image { src: String, caption: Option<String>, attrs: Attributes },
    Table { headers: Vec<Vec<Inline>>, rows: Vec<Vec<Vec<Inline>>> },
    Math { content: String, display: bool, label: Option<String> },
    Citation { key: String, style: CitationStyle },
    CrossReference { label: String, text: Option<String> },
    Theorem { label: Option<String>, content: Vec<Node> },
    Algorithm { label: Option<String>, caption: Option<String>, content: Vec<Node> },
    CodeBlock { language: Option<String>, label: Option<String>, caption: Option<String>, content: String },
}
```

### Layout Metadata
```rust
pub struct LayoutMetadata {
    pub page_size: PageSize,
    pub margins: Margins,
    pub font_size: f64,
    pub wrap_zones: Vec<WrapZone>,
    pub page_breaks: Vec<usize>,
}

pub struct Attributes {
    pub float: Option<FloatPosition>,
    pub width: Option<Dimension>,
    pub height: Option<Dimension>,
    pub label: Option<String>,
    pub caption: Option<String>,
}
```

### Document Metadata
```rust
pub struct DocumentMetadata {
    pub title: Option<String>,
    pub author: Option<String>,
    pub date: Option<String>,
    pub page_size: Option<PageSize>,
    pub margins: Option<Margins>,
    pub font_size: Option<f64>,
}
```

## API Specifications

### Core Functions
```rust
// Main compilation function
pub fn compile(input: &str, output_path: &Path, format: OutputFormat) -> Result<(), CompileError>

// Parser functions
pub fn parse_markdown(input: &str) -> Result<Document, ParseError>
pub fn build_ast(events: Vec<Event>) -> Result<Node, ASTError>

// Layout functions
pub fn calculate_layout(ast: &Node, metadata: &DocumentMetadata) -> Result<LayoutMetadata, LayoutError>
pub fn calculate_wrap_zones(floats: &[Float], content: &[Content]) -> Vec<WrapZone>

// Renderer functions
pub fn render_pdf(ast: &Node, layout: &LayoutMetadata) -> Result<Vec<u8>, RenderError>
pub fn render_html(ast: &Node) -> Result<String, RenderError>
pub fn render_latex(ast: &Node) -> Result<String, RenderError>
```

### CLI Interface
```rust
#[derive(Parser)]
enum Commands {
    Compile {
        input: Vec<PathBuf>,
        #[arg(short, long)]
        output: Option<PathBuf>,
        #[arg(short, long)]
        template: Option<String>,
        #[arg(long)]
        format: Option<OutputFormat>,
    },
    Check { input: PathBuf },
    Watch { input: PathBuf, output: Option<PathBuf> },
    Init { template: Option<String> },
    Template { command: TemplateCommands },
    Plugin { command: PluginCommands },
}
```

## User Interface Requirements

### CLI Commands
- `editio compile document.md -o output.pdf` - Basic compilation
- `editio compile document.md -t ieee-template -o output.pdf` - Template usage
- `editio compile chapter1.md chapter2.md -o book.pdf` - Multi-file input
- `editio compile document.md --format html -o output.html` - Format specification
- `editio watch document.md -o output.pdf` - Watch mode
- `editio check document.md` - Syntax validation
- `editio init --template ieee` - Project initialization
- `editio template list/install/search` - Template management
- `editio plugin list/install/search` - Plugin management

### Configuration
YAML front matter for documents:
```yaml
---
title: "My Academic Paper"
author: "John Doe"
date: "2025-01-27"
page-size: letter
margin-top: 1in
margin-bottom: 1in
margin-left: 1.5in
margin-right: 1in
font-size: 12pt
---
```

Configuration file (`editio.toml`):
```toml
[document]
title = "My Academic Paper"
author = "Author Name"

[output]
default-format = "pdf"
output-dir = "build"

[template]
name = "ieee-template"

[plugins]
enabled = ["editio-diagrams", "editio-mermaid"]
```

## Performance Requirements

### Compilation Speed Targets
- **Typical 20-page paper**: <1 second (target: ~50-100ms)
- **Large 100-page document**: <1 second (target: ~200-600ms)
- **Very large 1000+ pages**: Comparable to LaTeX (acceptable)
- **Overall**: 5-10x faster than LaTeX for typical and large documents

### Performance Strategy
- Two-pass layout system for optimal figure placement
- Parallelization where possible (layout calculation, rendering)
- Incremental compilation for watch mode
- Memory-efficient streaming for large documents
- Native Rust math renderer (Phase 3, replace pdflatex subprocess)

## Security Considerations

### Local Processing
- All processing happens locally on user's machine
- No network calls except optional plugin installation
- No data collection or telemetry
- Documents and bibliography files remain private

### Plugin Security
- WASM plugins run in sandboxed environment
- Dylib plugins require explicit user trust
- Plugin permissions system (read files, write output, no network/system calls by default)
- Optional plugin signing for registry plugins (post-MVP)

### File System Access
- Only reads specified input files
- Only writes to specified output location
- No access to other files unless explicitly specified
- Respects user's file system permissions

## External Dependencies

### Required Libraries
- **pulldown-cmark**: CommonMark-compatible parser (fast, extensible)
- **printpdf**: High-level PDF generation library
- **serde-yaml**: YAML parsing for front matter and templates
- **clap**: CLI argument parsing
- **wasmtime/wasmer**: WASM runtime for plugin system

### External Tools
- **pdflatex**: Math rendering for MVP (subprocess call)
- **KaTeX**: Client-side math rendering for HTML output
- **Git**: Plugin installation from repositories

### Optional Dependencies
- **CSL library**: Citation style processing (post-MVP)
- **docx-rs**: Word document generation
- **bibtex-parser**: BibTeX file processing

## Critical Technical Requirements

### Two-Pass Layout Engine
1. **Pass 1**: Parse all content, identify floated elements, calculate optimal placement
2. **Pass 2**: Generate final layout with text flow around figures
3. **Key capability**: Reliable text wrapping around figures including with lists
4. **Performance**: Layout calculation must complete in <100ms for typical documents
5. **Memory efficiency**: Stream processing where possible within two-pass constraints

### Cross-Reference System
- Unified labeling system for all elements (`{label=fig:1}`)
- Reference syntax: `[@label]` or `[See Figure @label]`
- Automatic sequential numbering
- Compile-time resolution and validation
- Global numbering across multi-file documents
- Duplicate label detection and reporting

### Math Support
- **MVP**: LaTeX syntax parsing with pdflatex subprocess rendering
- **Post-MVP**: Native Rust math renderer for performance
- Support inline (`$E=mc^2$`) and display (`$$\int_0^1$$`) math
- Math cross-referencing with equation numbering
- Level 1 support: Basic symbols, fractions, superscripts/subscripts, roots, basic matrices
- Level 2 support: Aligned equations, cases, all matrix environments, multi-line equations

### Bibliography System
- BibTeX file parsing and processing
- Citation syntax: `[@author2024]` for references
- Basic citation styles: APA, MLA, Chicago, IEEE
- Author-year and numeric formats
- CSL (Citation Style Language) support for advanced formatting
- Bibliography section auto-generation

### Plugin Architecture
- Stable API crate (`editio-plugin`) designed from start
- WASM-based plugin system for safety
- Parser, AST, and renderer hooks
- Plugin lifecycle management and discovery
- Plugin permissions system (read files, write output, no network by default)
- Plugin signing and verification for registry plugins

## Error Handling and Edge Cases

### Compilation Errors
- **Missing pdflatex**: Render placeholder with warning, continue compilation
- **Invalid markdown syntax**: Clear error message with line number and context
- **Missing bibliography file**: Error with suggestion to create or specify file
- **Unresolved cross-reference**: Error listing missing label and location
- **Circular includes**: Error detection with cycle path shown
- **Math syntax error**: Error with LaTeX error message from parser

### File Handling Errors
- **Image file not found**: Error with file path and suggestion to check path
- **Template not found**: Error with suggestion to list available templates
- **Plugin load failure**: Error with plugin name and reason, continue without plugin
- **Invalid YAML front matter**: Clear error with YAML parsing error details

### Data Validation Errors
- **Table with inconsistent column count**: Warning, pad with empty cells or error based on severity
- **Duplicate labels**: Error listing all locations of duplicate label
- **Unused labels**: Warning (optional, configurable)
- **Very large documents (1000+ pages)**: Acceptable performance degradation, show progress indicator

### Runtime Error Recovery
- **Figure wrapping edge cases**: Extensive testing, fallback to inline placement if wrapping fails
- **Memory constraints**: Stream processing and memory optimization
- **Performance degradation**: Progress indicators for large documents

## Implementation Phases and Success Criteria

### Phase 1 (MVP) Success Criteria
- Compiles 20-page academic paper in <1 second
- Text wrapping around figures works reliably (including with lists)
- Cross-references work correctly with automatic numbering
- Basic math renders in PDF via pdflatex subprocess
- Bibliography generates correctly with basic citation styles
- Can compile real academic papers from test corpus
- CLI compilation works end-to-end
- All core formatting features working
- Comprehensive error handling for all edge cases

### Phase 2 (Feature Complete) Success Criteria
- All output formats work (PDF, LaTeX, HTML, Word)
- Document chaining works with cross-file references
- Template system with inheritance works
- All advanced academic extensions implemented
- Plugin system functional (can load and execute WASM plugins)
- Performance consistently 5-10x faster than LaTeX
- IDE integration with VSCode plugin
- Import/export functionality for major academic formats

### Phase 3 (Polish) Success Criteria
- Native Rust math renderer replaces pdflatex
- Performance optimized (meets all targets consistently)
- Comprehensive template library available
- Plugin ecosystem with central registry and marketplace
- Complete documentation and examples
- Visual regression testing suite
- Performance benchmarking vs LaTeX and Typst

## Testing Requirements

### Unit Testing
- Parser tests for all markdown extensions
- AST builder tests for all node types
- Layout engine tests (critical for figure wrapping)
- Cross-reference system tests
- Math parsing and rendering tests
- Bibliography processing tests

### Integration Testing
- End-to-end compilation tests for all output formats
- Test corpus of real academic documents
- Regression tests for figure wrapping with lists
- Multi-file document compilation tests
- Template application tests
- Plugin loading and execution tests

### Performance Testing
- Compilation speed benchmarks vs LaTeX
- Memory usage profiling for large documents
- Layout calculation performance tests
- Math rendering performance tests
- Plugin system overhead tests

### Visual Regression Testing
- PDF output validation (golden files)
- Cross-format consistency testing
- Template application verification
- Figure placement accuracy tests

## Quality Assurance

### Code Quality
- Comprehensive documentation for all public APIs
- Error handling for all failure modes
- Memory safety (Rust guarantees + careful unsafe usage)
- Performance profiling and optimization
- Security auditing for plugin system

### User Experience
- Clear, actionable error messages
- Intuitive CLI interface
- Comprehensive documentation with examples
- Migration guides from LaTeX, Typst, Pandoc, Word
- Community support and contribution guidelines