# Editio - Product Requirements Document

**Version:** 1.0  
**Date:** 2026-01-22  
**Status:** Draft  
**Author:** Editio Team

---

## 1. Executive Summary

Editio is an advanced markdown-based typesetting system designed specifically for academic writing. It combines the simplicity and familiarity of markdown with the powerful typesetting capabilities needed for scholarly publications, addressing key pain points in existing solutions like LaTeX and Typst.

**Problem Statement:**
Academic writers face significant challenges with current typesetting solutions:
- **LaTeX** is overly complex, has package compatibility issues, and unreliable text wrapping around figures (especially with lists)
- **Typst** is fast but uses non-standard markdown syntax and requires manual line-count anticipation for figure wrapping, making workflows clunky during revisions
- Existing markdown tools lack the sophisticated typesetting features required for academic publications

**Solution:**
Editio bridges this gap by providing a markdown-native solution with robust academic typesetting capabilities and blazing fast compilation times. The key differentiator is reliable, automatic text wrapping around figures (including with lists) without manual intervention.

**Who Benefits:**
- Academic researchers writing papers, theses, and books
- Academic institutions standardizing document formats
- Technical writers creating formal documentation

---

## 2. Goals & Success Metrics

### Goals
- Provide a markdown-compatible syntax that honors standard and advanced markdown features
- Enable flexible page, paragraph, and section formatting with intuitive controls
- Deliver fast compilation (target: <1 second for typical academic papers)
- Support multiple output formats (PDF, HTML, Word, LaTeX)
- Offer better workflow than LaTeX and Typst for academic writing
- Implement reliable text wrapping around figures, including with lists (key differentiator)

### Success Metrics
- **Compilation speed**: 5-10x faster than LaTeX for typical (10-50 pages) and large (100-500 pages) documents
  - Typical 20-page paper: <1 second (target: ~50-100ms)
  - Large 100-page document: <1 second (target: ~200-600ms)
  - Very large 1000+ pages: Comparable to LaTeX (acceptable)
- **Syntax compatibility**: 100% support for CommonMark and GitHub Flavored Markdown features
- **Figure wrapping**: Automatic and reliable text wrapping around figures, including with lists (key differentiator)
- **User satisfaction**: Reduced time-to-publish compared to LaTeX workflows
- **Performance**: As fast or FASTER than Typst

---

## 3. User Personas

1. **Academic Researchers** - Graduate students, postdocs, and faculty writing papers, theses, and books. They need a tool that's easier than LaTeX but more powerful than basic markdown, with reliable figure placement and fast compilation times.

2. **Academic Institutions** - Universities and research organizations standardizing document formats. They need consistent formatting, template support, and compatibility with existing academic workflows.

3. **Technical Writers** - Writers creating formal documentation. They benefit from markdown simplicity with professional typesetting capabilities.

4. **Book Authors** - Authors preferring markdown workflows. They need multi-file document support, cross-references, and professional output formats.

---

## 4. Feature Scope

### 4.1 MVP (Phase 1) - Core Feature

**Priority: HIGHEST**

Core functionality for a functional academic paper compiler with reliable figure wrapping.

| Feature | Description | Priority |
|---------|-------------|----------|
| Markdown Parsing | CommonMark-compatible parser with YAML-style attributes (`![caption](img.png){float=right width=50%}`) | P0 |
| Two-Pass Layout Engine | CSS-style float algorithm with automatic text wrapping around figures (including with lists) | P0 |
| PDF Output | High-quality PDF generation using `printpdf` with custom layout engine | P0 |
| Cross-References | Unified cross-reference system (`[@label]` or `[See Figure @fig:label]`) for all elements | P0 |
| Academic Extensions (P0) | Theorem/Proof environments, Algorithm/Pseudocode listings, Code listings with captions | P0 |
| Math Typesetting (Level 1) | Inline and display math with LaTeX syntax, basic symbols, fractions, superscripts/subscripts, roots, basic matrices. PDF rendering via pdflatex subprocess | P0 |
| Bibliography System | BibTeX parser, citation processing (`[@author2024]`), basic citation styles (APA, MLA, Chicago, IEEE), author-year and numeric formats | P0 |
| Figure Support | YAML-style syntax, automatic numbering, captions, cross-referencing, text wrapping | P0 |
| Table Support | Standard markdown tables, automatic numbering, captions, cross-referencing, basic column alignment | P0 |
| Document Formatting | YAML front matter, page settings (margins, page size, font size), headers/footers, page numbering, section formatting, paragraph formatting | P0 |
| CLI Interface | `editio compile <file> -o <output>` and `editio check <file>` commands | P0 |

### 4.2 Phase 2 - Enhancements

**Priority: HIGH**

| Feature | Description | Priority |
|---------|-------------|----------|
| Additional Output Formats | LaTeX output (Priority #2), HTML output with KaTeX (Priority #3), Word output with tracked changes (Priority #4) | P1 |
| Document Chaining | Pandoc-like CLI syntax for multiple files, inline includes, cross-file references, global numbering | P1 |
| Template System | YAML-based templates with inheritance/composition, built-in templates (IEEE, ACM, university theses) | P1 |
| Plugin System | WASM-based plugin architecture, plugin manager, parser/AST/renderer hooks, plugin discovery and distribution | P1 |
| Advanced Academic Extensions (P1) | Complex table features, custom list numbering, landscape pages, appendix sections, structured blocks, author affiliations, acronym/glossary, block quotations | P1 |
| Advanced Math (Level 2) | Aligned equations, cases, all matrix environments, multi-line equations, custom operators | P1 |

### 4.3 Phase 3 - Nice to Have

**Priority: MEDIUM**

| Feature | Description | Priority |
|---------|-------------|----------|
| Performance Optimization | Parallelization, caching, incremental compilation, native Rust math renderer (replace pdflatex) | P2 |
| Extended Template Library | Templates for Pediatrics, JBC, JCI, Nature, additional journal formats | P2 |
| Plugin Ecosystem | Central plugin registry, plugin marketplace, plugin development tools, comprehensive documentation | P2 |
| Advanced Academic Extensions (P2) | Marginal notes/side notes, dedication/acknowledgments pages, multi-column layouts | P2 |
| IDE Integration | VSCode plugin/Language Server, syntax highlighting, IntelliSense, live preview | P2 |
| Import/Export | Pandoc markdown → Editio, LaTeX → Editio, Word → Editio, Typst → Editio | P2 |
| Advanced Features | Table of contents, list of figures/tables, index generation, color support, advanced headers/footers | P2 |

---

## 5. Data Model

### 5.1 AST (Abstract Syntax Tree) Structure

The core data model is an AST representing the document structure:

```rust
// Core AST node types (editio-ast crate)
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
    // ... other node types
}
```

### 5.2 Rust Types and Enums

Key types needed:

```rust
// Layout metadata
pub struct LayoutMetadata {
    pub page_size: PageSize,
    pub margins: Margins,
    pub font_size: f64,
    pub wrap_zones: Vec<WrapZone>,
    pub page_breaks: Vec<usize>,
}

// Attributes for images, tables, etc.
pub struct Attributes {
    pub float: Option<FloatPosition>,
    pub width: Option<Dimension>,
    pub height: Option<Dimension>,
    pub label: Option<String>,
    pub caption: Option<String>,
}

// Citation styles
pub enum CitationStyle {
    AuthorYear,
    Numeric,
}

// Page settings from YAML front matter
pub struct DocumentMetadata {
    pub title: Option<String>,
    pub author: Option<String>,
    pub date: Option<String>,
    pub page_size: Option<PageSize>,
    pub margins: Option<Margins>,
    pub font_size: Option<f64>,
}
```

### 5.3 Bibliography Data Structure

| Field | Type | Description |
|--------|------|-------------|
| Entry Key | `String` | Unique identifier (e.g., "smith2024") |
| Entry Type | `EntryType` | article, book, inproceedings, etc. |
| Fields | `HashMap<String, String>` | title, author, year, journal, etc. |
| Citation Format | `CitationFormat` | Author-year or numeric style |

---

## 6. Technical Architecture

### 6.1 External APIs Required

| Component | Method | Use Case | Notes |
|-----------|--------|----------|-------|
| pdflatex | Subprocess | Math rendering in PDF (MVP) | Shell out to pdflatex for math, extract PDF fragments |
| KaTeX (HTML) | Library | Math rendering in HTML | Client-side math rendering for HTML output |
| CSL Library | Library | Citation style processing | Process .csl files for advanced citation formatting (post-MVP) |

### 6.2 Core Rust Functions

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

### 6.3 Background Jobs

Not applicable - Editio is a CLI tool that runs synchronously. Future watch mode will use file system watchers.

### 6.4 File Structure

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
│   ├── editio-plugin/       # Plugin API crate (stable interface - design from start)
│   └── editio-plugin-manager/ # Plugin management (WASM/dylib loading)
├── tests/                   # Integration tests
├── examples/                # Example documents
├── templates/               # Built-in templates
└── docs/                    # Documentation
```

---

## 7. User Interface

### 7.1 Access Point

- **CLI Tool**: `editio` command-line application
- **Installation**: Via Cargo (`cargo install editio`) or pre-built binaries
- **Usage**: Command-line interface with subcommands

### 7.2 CLI Commands

**Main Commands:**
```bash
# Compile markdown to PDF
editio compile document.md -o output.pdf

# Compile with template
editio compile document.md -t ieee-template -o output.pdf

# Multiple input files
editio compile chapter1.md chapter2.md -o book.pdf

# Specify format
editio compile document.md --format html -o output.html

# Watch mode (for development)
editio watch document.md -o output.pdf

# Validate syntax
editio check document.md

# Initialize new project
editio init --template ieee

# Template management
editio template list
editio template install <name>

# Plugin management
editio plugin list
editio plugin install <repo>
editio plugin search <keyword>
```

**Configuration File (`editio.toml`):**
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
disabled = ["editio-experimental"]

[syntax]
default-style = "yaml"  # yaml | html | directive | auto
allow-mixed = true
warn-mixed = true
```

---

## 8. API Routes

### 8.1 CLI Command Structure

Editio is a CLI tool, not a web service. The "API" is the command-line interface:

```rust
// CLI structure using clap
#[derive(Parser)]
#[command(name = "editio")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
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
    Check {
        input: PathBuf,
    },
    Watch {
        input: PathBuf,
        #[arg(short, long)]
        output: Option<PathBuf>,
    },
    Init {
        #[arg(long)]
        template: Option<String>,
    },
    Template {
        #[command(subcommand)]
        command: TemplateCommands,
    },
    Plugin {
        #[command(subcommand)]
        command: PluginCommands,
    },
}
```

### 8.2 Library API (for programmatic use)

If used as a library:

```rust
use editio_core::{compile, CompileOptions};

let options = CompileOptions {
    input: "document.md",
    output: "output.pdf",
    format: OutputFormat::Pdf,
    template: None,
};

compile(&options)?;
```

---

## 9. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Missing pdflatex for math rendering | Render placeholder with warning, continue compilation |
| Invalid markdown syntax | Clear error message with line number and context |
| Missing bibliography file | Error with suggestion to create or specify file |
| Unresolved cross-reference | Error listing missing label and location |
| Circular includes in document chaining | Error detection with cycle path shown |
| Image file not found | Error with file path and suggestion to check path |
| Table with inconsistent column count | Warning, pad with empty cells or error based on severity |
| Math syntax error | Error with LaTeX error message from parser |
| Very large documents (1000+ pages) | Acceptable performance degradation, show progress indicator |
| Figure wrapping edge cases (lists, nested elements) | Extensive testing, fallback to inline placement if wrapping fails |
| Duplicate labels | Error listing all locations of duplicate label |
| Unused labels | Warning (optional, configurable) |
| Invalid YAML front matter | Clear error with YAML parsing error details |
| Template not found | Error with suggestion to list available templates |
| Plugin load failure | Error with plugin name and reason, continue without plugin |

---

## 10. Security & Privacy

- **Authentication**: Not applicable - CLI tool runs locally with user's file system permissions
- **Authorization**: Not applicable - no multi-user system
- **Data privacy**: 
  - All processing happens locally
  - No network calls (except optional plugin installation from Git repos)
  - No data collection or telemetry (configurable)
  - Bibliography files and documents remain on user's machine
- **Plugin Security**:
  - WASM plugins run in sandboxed environment
  - Dylib plugins require explicit user trust
  - Plugin permissions system (read files, write output, no network/system calls by default)
  - Optional plugin signing for registry plugins (post-MVP)
- **File System Access**: 
  - Only reads specified input files
  - Only writes to specified output location
  - No access to other files unless explicitly specified

---

## 11. Implementation Phases

### Phase 1: MVP (Target: 6-8 months / 30 weeks)

**Week 1-2: Project Setup and Core Infrastructure**
- [ ] Initialize Rust workspace with all crate structure
- [ ] Set up `Cargo.toml` workspace configuration
- [ ] Create basic crate structure (editio, editio-core, editio-ast, editio-parser, editio-layout, editio-render, editio-pdf, editio-bib, editio-math, editio-plugin)
- [ ] Set up development environment (Rust, testing, CI/CD)
- [ ] Create basic CLI structure

**Week 3-4: Markdown Parser Foundation**
- [ ] Integrate `pulldown-cmark` as base parser
- [ ] Implement CommonMark parsing (all standard features)
- [ ] Extend parser for YAML-style attributes
- [ ] Build AST builder (`editio-ast` crate)
- [ ] Basic markdown → AST conversion
- [ ] Unit tests for parser

**Week 5-8: Two-Pass Layout Engine (Core Differentiator)**
- [ ] Pass 1: Layout Calculation
  - Parse all files and build complete AST
  - Collect all floating figures with attributes
  - Calculate text flow (identify paragraphs, lists, etc.)
  - Implement CSS-style float algorithm
  - Calculate wrap zones for each floating figure
  - Handle lists wrapping around figures (key differentiator)
  - Optimize figure placement to minimize page breaks
  - Calculate page breaks based on content
- [ ] Pass 2: Layout Data Structure
  - Create layout representation (page breaks, figure positions, wrap zones)
  - Store layout metadata for rendering phase
- [ ] Testing: Unit tests for float algorithm, integration tests for wrap zone calculation, regression tests for figure wrapping with lists

**Week 9-12: PDF Generation**
- [ ] Integrate `printpdf` library
- [ ] Implement PDF writer (`editio-pdf` crate)
- [ ] Render AST using layout data from layout engine
- [ ] Implement text rendering with wrap zones
- [ ] Implement figure placement (absolute positioning based on layout)
- [ ] Implement text flowing around figures (using wrap zones)
- [ ] Handle lists with text wrapping (critical differentiator)
- [ ] Basic page formatting (margins, page size)
- [ ] Font embedding (Times New Roman, system fonts)
- [ ] Basic headers/footers with page numbers
- [ ] Unit tests for PDF rendering
- [ ] Integration tests

**Week 13-14: Academic Extensions (P0 - MVP)**
- [ ] Cross-References - Unified system
  - Label tracking (`{label=fig:setup}`)
  - Reference syntax (`[@label]` or `[See @label]`)
  - Reference resolution (compile-time)
  - Automatic numbering (sequential)
- [ ] Theorem/Proof Environments
  - Block directive syntax: `:::{theorem}{label=thm:1}...:::`
  - Auto-numbering
  - Cross-referencing
- [ ] Algorithm/Pseudocode Listings
  - Block directive syntax: `:::{algorithm}{label=alg:1 caption="..."}...:::`
  - Caption support
  - Auto-numbering
- [ ] Code Listings with Captions
  - Block directive syntax: `:::{code}{label=code:1 caption="..." language=rust}...:::`
  - Auto-numbering
  - Cross-referencing

**Week 15-16: Math Typesetting**
- [ ] Parse LaTeX math syntax (`$E=mc^2$`, `$$\int_0^1$$`)
  - Math preprocessor extracts math expressions before pulldown-cmark
  - Supports inline math (`$...$`) and display math (`$$...$$`)
  - Math placeholders converted to AST Math nodes
- [ ] Implement Level 1 math support (parsing):
  - Inline and display math parsing
  - Math labels: `$$\int_0^1$${label=eq:1}`
- [ ] PDF Math Rendering: Shell out to `pdflatex` for math
  - Create minimal LaTeX files with math
  - Call pdflatex subprocess
  - Extract/embed PDF fragments into main PDF (MVP: placeholder, post-MVP: full embedding)
- [ ] Math cross-referencing (equation numbering via labels)
- [ ] Error handling for missing pdflatex (renders placeholder if pdflatex unavailable)
- [ ] Unit tests for math preprocessing
- [ ] Integration with PDF renderer (MathElement support)
- [ ] MathElement added to layout engine

**Week 17-18: Bibliography System**
- [ ] BibTeX Parser (`editio-bib` crate)
  - Parse `.bib` files (BibTeX format - Priority #1)
  - Support BibLaTeX features (basic support - post-MVP for full BibLaTeX)
- [ ] Citation Processing
  - Parse inline citations: `[@author2024]`
  - Support both author-year and numeric formats
  - Collect all citations from document
  - Resolve citations from bibliography
  - Format citations according to style
- [ ] Citation Styles (Basic)
  - Implement basic citation formatting (MVP: author-year and numeric)
  - Basic bibliography entry formatting (article, book, inproceedings)
  - Default styles: APA-style formatting (basic), numeric
  - Generate bibliography entries (rendering in PDF post-MVP enhancement)
- [ ] Bibliography Integration
  - Citation parsing integrated with markdown parser
  - Unified citation/cross-reference parser (distinguishes `[@fig:1]` vs `[@smith2024]`)
  - Citation resolution in document AST
  - Basic bibliography formatting

**Week 19-20: Figure and Table Support**
- [ ] Image Support
  - YAML-style syntax: `![caption](img.png){float=right width=50% label=fig:1}` (already implemented)
  - Figure numbering (automatic sequential)
  - Figure captions
  - Cross-referencing to figures (already implemented via label system)
  - Image loading structure (placeholder rendering for MVP)
- [ ] Table Support
  - Standard markdown table parsing (already implemented via pulldown-cmark)
  - Table rendering structure
  - Table rendering implementation (grid with borders, header row, data rows, column separators, row separators)
  - Table numbering collection (from document labels)
  - Table captions (formatting: "Table N: Caption" or "Table N")
  - Table numbering (automatic sequential)
  - Cross-referencing to tables (already implemented via label system)
  - Column alignment support (left, center, right, justify - basic implementation)
  - Comprehensive table tests

**Week 21-22: Basic Document Formatting**
- [ ] YAML Front Matter Parsing
  - Parse document metadata (title, author, date)
  - Parse page settings (margins, page size, font size)
    - Dimension parsing (mm, cm, in, pt, px, %, em)
    - Page size parsing (letter, A4, legal, custom)
    - Margin parsing (top, bottom, left, right)
    - Font size parsing
- [ ] Page-Level Controls
  - Apply margins and page size (integrated into layout engine)
  - Basic headers/footers (title/author in header, page number in footer)
  - Page numbering (centered in footer, sequential numbering)
- [ ] Section Formatting
  - Automatic heading numbering (hierarchical: 1, 1.1, 1.1.1)
  - Section breaks (page breaks) (level 1 headings force page breaks)
- [ ] Paragraph Formatting
  - Paragraph attribute parsing from markdown (HTML comment syntax: `<!-- align=center spacing=1.5 indent=12pt -->`)
  - Basic paragraph alignment (left, center, right, justify)
  - Line spacing (single, 1.5, double, or numeric multiplier)
  - Indentation (first-line indent and hanging indent)
  - Full text justification (word-by-word rendering with proper spacing distribution)
  - Improved text width calculation (character-specific width estimation)

**Week 23-24: Plugin System Architecture**
- [ ] Design `editio-plugin` API Crate
  - Define plugin traits/interfaces:
    - `ParserHook` trait
    - `ASTHook` trait
    - `RendererHook` trait
  - Define shared types
  - Define plugin metadata structure
  - Document plugin API (stable interface)
- [ ] Plan Plugin Manager
  - Design plugin loading interface
  - Plan WASM runtime integration (no implementation)
  - Plan plugin discovery mechanism

**Week 25-26: CLI and Configuration**
- [ ] CLI Commands
  - `editio compile <file> -o <output>` - Basic compilation
  - `editio check <file>` - Validate syntax
  - Basic error messages (file-level, format-specific)
  - Default output file naming (input.ext → input.pdf)
- [ ] Configuration File
  - Parse `editio.toml` or `.editio.yaml`
  - Document settings
  - Output settings
  - Basic plugin configuration (structure only)

**Week 27-28: Testing and Quality Assurance**
- [ ] Unit Tests
  - Parser tests
  - AST builder tests
  - Layout engine tests (critical for figure wrapping)
- [ ] Integration Tests
  - End-to-end compilation tests
  - Test corpus of academic documents (real papers)
  - Regression tests for figure wrapping with lists
- [ ] Golden File Testing
  - PDF output validation (golden files)
  - Visual regression testing
  - Compare against LaTeX output (where applicable)
- [ ] Performance Benchmarks
  - Compare compilation speed against LaTeX
  - Measure memory usage
  - Validate performance targets (5-10x faster)

**Week 29-30: MVP Polish**
- [ ] Fix critical bugs
- [ ] Performance optimization
- [ ] Error message improvements
- [ ] Basic user documentation (quick start guide)
- [ ] Example documents
- [ ] MVP release preparation

### Phase 2: Feature Complete (Target: 4-6 months after MVP)

**Month 7-8: Additional Output Formats**
- [ ] LaTeX Output (`editio-latex` crate)
  - Convert AST to LaTeX code
  - Preserve formatting as much as possible
  - Handle figures, tables, math, bibliography
  - Generate clean LaTeX (may require minor edits)
- [ ] HTML Output (`editio-html` crate)
  - Semantic HTML5 generation
  - CSS styling
  - KaTeX integration for math rendering
  - Interactive cross-references (anchor links)
  - Responsive design
- [ ] Word Output (`editio-word` crate)
  - DOCX generation using `docx-rs` or similar
  - Preserve formatting (as close as possible to PDF)
  - Support Word styles
  - Tracked changes support
  - Comments support
  - Office 365 compatibility

**Month 9: Document Chaining**
- [ ] CLI Multi-File Support
  - Parse multiple input files: `editio compile file1.md file2.md -o output.pdf`
  - Process files in order
  - Combine into single output
- [ ] Inline Includes (Optional)
  - Parse `{{ include "file.md" }}` syntax
  - Process includes recursively
  - Handle circular includes (error)
- [ ] Cross-File References
  - Global label registry across all files
  - Cross-file reference resolution
  - Global sequential numbering (default)
  - Optional chapter-based numbering for theses

**Month 10: Template System**
- [ ] Template Engine (`editio-template` crate)
  - YAML-based template format
  - Template loading (project-local and global)
  - Variable substitution
- [ ] Template Features
  - Template inheritance (templates extend base templates)
  - Template composition (combine parts)
  - Template variables and filters
- [ ] Built-in Templates
  - Base academic paper template
  - IEEE template
  - ACM template
  - University thesis template
- [ ] Template Management
  - `editio template list` command
  - `editio template install <name>` command
  - Template gallery

**Month 11: Advanced Academic Extensions (P1)**
- [ ] Complex Table Features (D)
  - Multi-row headers
  - Cell spanning
  - Rotated headers
- [ ] Custom List Numbering (E)
  - (a), (b), (c) style
  - i., ii., iii. style
  - A., B., C. style
- [ ] Landscape Pages (F)
  - Landscape page orientation
  - Wide table/figure support
- [ ] Appendix Sections (G)
  - Special numbering (A, B, C)
- [ ] Structured Blocks (H)
  - Abstract blocks
  - Keywords blocks
- [ ] Author Affiliations (I)
  - Complex author lists
  - Affiliation superscripts
- [ ] Acronym/Glossary (J)
  - Auto-expand on first use
  - Glossary generation
- [ ] Block Quotations (K)
  - Quotations with attribution
  - Citation support

**Month 12: Plugin System Implementation**
- [ ] Plugin Manager (`editio-plugin-manager` crate)
  - WASM runtime integration (`wasmtime` or `wasmer`)
  - Plugin loading (WASM)
  - Plugin lifecycle management (load, initialize, execute, cleanup)
- [ ] Plugin Discovery
  - Local plugin discovery (`~/.editio/plugins/`, project-local)
  - Git repository plugin installation
  - Plugin registry (basic structure)
- [ ] Plugin API Implementation
  - Parser hooks (custom markdown extensions)
  - AST hooks (transformations, validations)
  - Renderer hooks (custom output formats)
- [ ] Plugin Management CLI
  - `editio plugin list`
  - `editio plugin install <repo>`
  - `editio plugin remove <name>`
  - `editio plugin search <keyword>`
  - `editio plugin enable/disable <name>`
- [ ] Core Example Plugins
  - Mermaid diagram plugin (example)
  - Additional citation style plugin (example)
  - Plugin documentation and examples

**Month 13: Advanced Features**
- [ ] Advanced Math (Level 2)
  - Aligned equations
  - Cases environments
  - All matrix environments
  - Native Rust math renderer (start migration from pdflatex)
- [ ] Advanced Layout Features
  - Multi-column layouts (P2)
  - Landscape pages
  - Page backgrounds
  - Custom fonts
- [ ] Table of Contents
  - Auto-generation from headings
  - List of figures
  - List of tables
- [ ] Advanced Document Features
  - Index generation
  - Color support
  - Advanced headers/footers (even/odd pages)

**Month 14: Import/Export**
- [ ] Import Formats (Priority Order)
  1. Pandoc markdown → Editio (#1)
  2. LaTeX → Editio basic conversion (#2)
  3. Word → Editio (#3)
  4. Typst → Editio (#4)
- [ ] Export Refinements
  - LaTeX output improvements
  - HTML output enhancements
  - Word output fidelity improvements

### Phase 3: Polish and Optimization (Target: 3-4 months after Phase 2)

**Month 15-16: Performance Optimization**
- [ ] Layout Engine Optimization
  - Parallelize layout calculation where possible
  - Optimize wrap zone calculations
  - Cache layout calculations
  - Incremental layout updates (if document changed)
- [ ] Native Math Renderer
  - Build native Rust LaTeX math parser (Level 1)
  - Replace pdflatex subprocess (eliminate ~100ms overhead)
  - Optimize math rendering performance
- [ ] Compilation Speed Optimization
  - Profile and optimize hot paths
  - Parallel AST building
  - Optimize PDF generation
  - Achieve 5-10x faster than LaTeX consistently
- [ ] Memory Optimization
  - Stream processing where possible (within two-pass constraints)
  - Optimize AST representation
  - Reduce memory footprint for large documents

**Month 17: Extended Template Library**
- [ ] Create templates for all requested journals:
  - Pediatrics
  - JBC
  - JCI
  - Nature
  - Additional IEEE/ACM variants
- [ ] University thesis templates (various universities)
- [ ] Template documentation and examples
- [ ] Template gallery website/documentation

**Month 18: Plugin Ecosystem Maturity**
- [ ] Central Plugin Registry
  - Design registry architecture
  - Implement plugin repository
  - Plugin search and discovery
  - Plugin verification/auditing
- [ ] Plugin Distribution
  - Plugin publishing workflow
  - Version management
  - Dependency resolution
  - Plugin signing (for registry)
- [ ] Plugin Development Tools
  - `editio plugin create <name>` - Scaffold new plugin
  - Plugin development SDK
  - Plugin debugging tools
  - Hot reloading for development
- [ ] Plugin Examples and Documentation
  - Comprehensive plugin development guide
  - Multiple example plugins
  - Best practices documentation

**Month 19: Advanced Academic Extensions (P2)**
- [ ] Marginal Notes / Side Notes (L)
  - Side margin commentary
- [ ] Dedication/Acknowledgments Pages (M)
  - Special formatting blocks
- [ ] Multi-Column Layouts (N)
  - Two-column and three-column sections
  - Column breaks

**Month 20: IDE Integration and Tooling**
- [ ] VSCode Plugin/Language Server
  - Syntax highlighting for Editio markdown
  - IntelliSense/autocomplete for syntax
  - Cross-reference validation
  - Live preview
  - Language Server Protocol implementation
- [ ] Watch Mode
  - `editio watch <file> -o <output>`
  - Auto-recompile on file changes
- [ ] Preview Mode
  - Auto-open PDF/HTML after compilation
  - Incremental compilation (recompile only changed sections)
- [ ] Development Tools
  - Debug logging
  - Performance profiling tools
  - AST visualization

**Month 21: Documentation and Community**
- [ ] User Documentation
  - Complete user guide
  - Full syntax reference
  - Template creation guide
  - Migration guides (LaTeX, Typst, Pandoc, Word)
- [ ] Developer Documentation
  - Plugin development guide
  - API documentation (all crates)
  - Architecture documentation
  - Contributing guide
- [ ] Examples and Tutorials
  - Sample academic papers (various formats)
  - Tutorial videos/articles
  - User-contributed examples
  - Community showcase

**Month 22: Ecosystem Integration**
- [ ] CI/CD Integration
  - GitHub Actions workflow examples
  - GitLab CI examples
  - Automated compilation on push
- [ ] Version Control Integration
  - `editio git-hooks install` command (optional helper)
  - Git workflow documentation
  - Diff-friendly output validation
- [ ] Community Resources
  - Plugin marketplace
  - Template gallery
  - Community forum/wiki
  - Example repository

---

## 12. Open Questions

1. **Math Rendering Performance**: Should we prioritize native Rust math renderer earlier, or is pdflatex subprocess acceptable for MVP? (Decision: Use pdflatex for MVP, native renderer in Phase 3)
2. **Plugin System Timing**: Should plugin system be designed earlier even if implementation is later? (Decision: Design API crate in MVP, full implementation in Phase 2)
3. **Multi-Syntax Support**: Should we support multiple syntax styles (YAML, HTML, directives) from MVP or start with YAML only? (Decision: YAML-style only for MVP, add others in Phase 2)
4. **CSL Library**: Should we use a Rust CSL library or implement basic citation formatting ourselves? (Decision: Basic formatting for MVP, full CSL support in Phase 2)
5. **Image Embedding**: Should full image embedding be in MVP or is placeholder rendering acceptable? (Decision: Placeholder for MVP, full embedding in Phase 2)
6. **Bibliography Section Rendering**: Should bibliography section be rendered in PDF for MVP? (Decision: Citation processing for MVP, bibliography section rendering in Phase 2)

---

## 13. References

- **CommonMark Specification**: https://commonmark.org/
- **GitHub Flavored Markdown**: https://github.github.com/gfm/
- **Pandoc Markdown**: https://pandoc.org/MANUAL.html#pandocs-markdown
- **LaTeX Documentation**: https://www.latex-project.org/help/documentation/
- **Typst Documentation**: https://typst.app/docs/
- **pulldown-cmark**: Rust CommonMark parser
- **printpdf**: Rust PDF generation library
- **KaTeX**: Math rendering for HTML
- **BibTeX Format**: https://www.bibtex.org/format/
- **CSL (Citation Style Language)**: https://citationstyles.org/
- **WASM Runtime**: wasmtime or wasmer for plugin system

---

## Appendix

### A. Example Markdown Document

```markdown
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

# Introduction

This is a paragraph with a citation [@smith2024] and a cross-reference to [Figure @fig:setup].

![Experimental Setup](setup.png){float=right width=50% label=fig:setup}

The figure shows our experimental setup. We can also reference equations like [Equation @eq:einstein].

$$E = mc^2$${label=eq:einstein}

## Methods

:::{theorem}{label=thm:main}
This is a theorem with automatic numbering.
:::

:::{algorithm}{label=alg:1 caption="Main Algorithm"}
1. Step one
2. Step two
3. Step three
:::

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
{label=tbl:1 caption="Results Table"}

### Results

See [Table @tbl:1] for results.

## References

@smith2024
```

### B. Additional Technical Details

**Key Libraries:**
- **Markdown Parser**: `pulldown-cmark` (CommonMark compliant, fast, extensible)
- **PDF Generation**: `printpdf` (high-level API, PDF creation focus)
- **HTML Generation**: `maud`, `askama`, or manual generation (evaluate options)
- **Word Generation**: `docx-rs` or similar (evaluate options)
- **YAML Parsing**: `serde-yaml`
- **BibTeX Parsing**: `bibtex-parser` or custom parser (evaluate options)
- **Math Rendering (PDF)**: Shell out to `pdflatex` (MVP) → Native Rust renderer (post-MVP)
- **Math Rendering (HTML)**: KaTeX (primary), MathJax (fallback)
- **Template Engine**: `handlebars` or `tera` (evaluate options)
- **CSL Processing**: CSL library for citation styles (evaluate Rust options)
- **WASM Runtime**: For plugin system (e.g., `wasmtime` or `wasmer`)

**Critical Path Items:**
1. Two-pass layout engine with CSS-style float algorithm
2. Text wrapping around figures including with lists
3. PDF generation with custom layout
4. Cross-references system
5. Basic math rendering
6. Bibliography system
7. Figure/table support with numbering

**High Risk Items:**
- Text wrapping algorithm - Complex, critical differentiator (allocate extra time)
- Two-pass layout performance - Ensure meets <1 second target (optimize early)
- Figure wrapping with lists - Known LaTeX/Typst issue, must work (test extensively)
- PDF math embedding - pdflatex integration complexity (research thoroughly)

**Success Criteria by Phase:**

**Phase 1 (MVP) Success Criteria:**
- Compiles 20-page academic paper in <1 second
- Text wrapping around figures works reliably (including with lists)
- Cross-references work correctly
- Basic math renders in PDF
- Bibliography generates correctly
- Can compile real academic papers from test corpus
- CLI compilation works end-to-end
- All core formatting features working

**Phase 2 (Feature Complete) Success Criteria:**
- All output formats work (PDF, LaTeX, HTML, Word)
- Document chaining works with cross-file references
- Template system with inheritance works
- All P1 academic extensions implemented
- Plugin system functional (can load and execute WASM plugins)
- 5-10x faster than LaTeX for typical/large documents

**Phase 3 (Polish) Success Criteria:**
- Native Rust math renderer replaces pdflatex
- Performance optimized (meets all targets consistently)
- Comprehensive template library available
- Plugin ecosystem with central registry
- VSCode plugin/Language Server working
- Complete documentation and examples
