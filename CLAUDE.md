# JSON Resume Theme Development Template

This guide provides instructions for creating a JSON Resume theme from scratch using Claude Code.

## JSON Resume Theme Requirements

### Core Requirements
1. **NPM Package Name**: Must be `jsonresume-theme-{name}`
2. **Export Function**: Must export a `render` function that:
   - Takes a JSON resume object as parameter
   - Returns a complete HTML string
   - Is "pure" with no side effects
   - Cannot use Node.js modules like `fs` or `http` (except during build)
3. **Self-Contained Output**: All CSS, fonts, and assets must be inline or base64 encoded
4. **Schema Compliance**: Follow [JSON Resume Schema](https://jsonresume.org/schema/)

### Basic Implementation Pattern
```javascript
const render = (resume) => {
  return '<h1>' + resume.basics.name + '</h1>'
}

module.exports = { render }
```

## Development Setup Commands

### Initialize New Theme Project
```bash
mkdir jsonresume-theme-{name}
cd jsonresume-theme-{name}
npm init -y
```

### Install Core Dependencies
```bash
# Essential for most themes
npm install handlebars moment

# Optional but common
npm install handlebars-wax  # For partials and helpers
npm install address-format  # For address formatting
```

### Install Development Dependencies
```bash
# Testing and quality
npm install --save-dev jest puppeteer jest-image-snapshot
npm install --save-dev eslint prettier
npm install --save-dev jest-handlebars  # If using Handlebars in tests

# For Handlebars template testing
npm install --save-dev jest-handlebars
```

### Test JSON Resume Locally
```bash
# Install resume-cli globally
npm install -g resume-cli

# Test your theme (run from theme directory)
resume export resume.html --theme .

# Generate PDF (requires puppeteer-cli)
npm install -g puppeteer-cli
puppeteer --wait-until networkidle0 --margin-top 0 --margin-right 0 --margin-bottom 0 --margin-left 0 --format A4 print resume.html resume.pdf
```

## Theme Architecture Patterns

### Option 1: Simple Single-File Theme
- Single `index.js` with embedded HTML/CSS strings
- Good for: Minimal themes, prototypes
- Example: Basic HTML template with inline styles

### Option 2: Template-Based Theme (Recommended)
- Separate template files (Handlebars, Mustache, etc.)
- External CSS file (inlined during render)
- Modular partials for sections
- Good for: Professional themes, maintainability

### Option 3: Build-Process Theme
- Source files compiled to final theme
- Asset optimization and bundling
- Good for: Complex themes with many assets

## Standard File Structure (Template-Based)

```
jsonresume-theme-{name}/
├── package.json
├── README.md
├── index.js              # Main entry point with render function
├── resume.json           # Sample resume for testing
├── src/
│   ├── resume.hbs        # Main HTML template
│   ├── style.css         # All CSS styles
│   └── partials/         # Handlebars partials
│       ├── basics.hbs    # Header/contact info
│       ├── work.hbs      # Work experience
│       ├── education.hbs # Education
│       ├── skills.hbs    # Skills
│       └── ...           # Other sections
└── __tests__/            # Visual regression tests
    └── visual.js
```

## Essential package.json Configuration

```json
{
  "name": "jsonresume-theme-{name}",
  "version": "1.0.0",
  "description": "JSON Resume theme",
  "main": "index.js",
  "scripts": {
    "test": "jest",
    "lint": "eslint *.js",
    "format": "prettier --write *.js src/**/*",
    "prepublishOnly": "npm run format && npm run lint && npm run test"
  },
  "keywords": ["jsonresume", "theme", "resume"],
  "license": "MIT"
}
```

## Core Implementation Steps

### 1. Create Main Entry Point (index.js)
```javascript
const fs = require('fs');
const handlebars = require('handlebars');
const moment = require('moment');

// Register common helpers
handlebars.registerHelper({
  formatDate: date => moment(date).format('MM/YYYY'),
  removeProtocol: url => url.replace(/.*?:\/\//g, ''),
  lowercase: str => str.toLowerCase()
});

function render(resume) {
  const css = fs.readFileSync(`${__dirname}/src/style.css`, 'utf-8');
  const template = fs.readFileSync(`${__dirname}/src/resume.hbs`, 'utf-8');
  
  return handlebars.compile(template)({
    style: `<style>${css}</style>`,
    resume
  });
}

module.exports = { render };
```

### 2. Create Sample Resume (resume.json)
```bash
# Download official sample
curl -o resume.json https://raw.githubusercontent.com/jsonresume/resume-schema/master/sample.resume.json
```

### 3. Create Base HTML Template (src/resume.hbs)
```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, user-scalable=no, minimal-ui">
  <title>{{resume.basics.name}}</title>
  {{{style}}}
</head>
<body>
  <main>
    {{> basics}}
    {{> work}}
    {{> education}}
    {{> skills}}
  </main>
</body>
</html>
```

### 4. Create Section Partials
Each section should check if data exists before rendering:
```handlebars
{{#if resume.work.length}}
<section class="work-section">
  <h2>Experience</h2>
  {{#each resume.work}}
  <div class="work-item">
    <h3>{{name}}</h3>
    <h4>{{position}}</h4>
    <p>{{summary}}</p>
  </div>
  {{/each}}
</section>
{{/if}}
```

### 5. Create CSS Styles (src/style.css)
- Use web fonts or embed font files as base64
- Ensure print-friendly styles
- Make responsive for different screen sizes
- Include proper typography and spacing

## JSON Resume Schema Sections

### Required Data Structure Understanding
- `basics` - Name, contact info, summary
- `work` - Employment history
- `education` - Educational background
- `skills` - Technical and soft skills
- `projects` - Personal/professional projects
- `volunteer` - Volunteer work
- `awards` - Recognition and awards
- `publications` - Published works
- `languages` - Language proficiencies
- `interests` - Personal interests
- `references` - Professional references

### Handling Optional Data
Always check if sections exist before rendering:
```handlebars
{{#if resume.work}}
  {{#if resume.work.length}}
    <!-- Render work section -->
  {{/if}}
{{/if}}
```

## Testing Setup

### Visual Regression Testing
```javascript
// __tests__/visual.js
const { toMatchImageSnapshot } = require('jest-image-snapshot');
const puppeteer = require('puppeteer');
const { render } = require('../index');
const resume = require('../resume.json');

expect.extend({ toMatchImageSnapshot });

test('visual regression', async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  const html = render(resume);
  await page.setContent(html);
  
  const screenshot = await page.screenshot({ fullPage: true });
  expect(screenshot).toMatchImageSnapshot();
  
  await browser.close();
});
```

## Common Handlebars Helpers

```javascript
handlebars.registerHelper({
  // Date formatting
  formatDate: date => moment(date).format('MM/YYYY'),
  
  // URL cleanup
  removeProtocol: url => url.replace(/.*?:\/\//g, ''),
  
  // String manipulation
  uppercase: str => str.toUpperCase(),
  lowercase: str => str.toLowerCase(),
  
  // Conditionals
  eq: (a, b) => a === b,
  
  // Array helpers
  first: arr => arr[0],
  last: arr => arr[arr.length - 1]
});
```

## Development Workflow

### 1. Setup Phase
- Initialize NPM package with correct naming
- Install dependencies
- Create basic file structure
- Download sample resume.json

### 2. Design Phase
- Create HTML structure in template
- Build CSS styles for visual design
- Ensure responsive and print layouts
- Test with sample data

### 3. Implementation Phase
- Break template into logical partials
- Add Handlebars helpers as needed
- Handle all JSON Resume schema sections
- Implement proper conditional rendering

### 4. Testing Phase
- Set up visual regression tests
- Test with various resume data
- Verify PDF generation works
- Cross-browser testing

### 5. Publishing Phase
- Run linting and formatting
- Update README with usage instructions
- Publish to NPM registry
- Test installation and usage

## Best Practices

### CSS Guidelines
- Use CSS custom properties for theming
- Ensure print styles with `@media print`
- Embed fonts to avoid external dependencies
- Use semantic class names
- Optimize for readability and ATS scanning

### Template Guidelines
- Always check for data existence before rendering
- Use semantic HTML elements
- Maintain accessibility standards
- Handle empty or missing sections gracefully
- Keep templates modular and reusable

### Performance Considerations
- Minimize CSS size while maintaining design quality
- Optimize embedded assets
- Use efficient Handlebars patterns
- Avoid complex logic in templates

## Troubleshooting

### Common Issues
1. **Theme not found**: Check NPM package name follows `jsonresume-theme-{name}` convention
2. **Assets not loading**: Ensure all external resources are embedded
3. **Template errors**: Validate Handlebars syntax and data structure assumptions
4. **PDF generation issues**: Check CSS print styles and page break handling

### Testing Commands
```bash
# Test theme locally
resume export test.html --theme .

# Debug with verbose output
resume export test.html --theme . --debug

# Test PDF generation
puppeteer print test.html test.pdf
```

## Publishing Checklist

- [ ] Package name follows `jsonresume-theme-{name}` convention
- [ ] Main field in package.json points to entry file
- [ ] Render function exports correctly
- [ ] All assets are embedded/inlined
- [ ] README includes installation and usage instructions
- [ ] Visual tests pass
- [ ] Works with resume-cli
- [ ] PDF generation produces good output
- [ ] No external dependencies in runtime code