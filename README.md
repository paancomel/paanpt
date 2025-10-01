# Kyros F&B Cost Calculator WordPress Plugin

This repository contains a WordPress plugin that delivers the Kyros F&B cost calculator as an admin experience. The plugin consumes menu and ingredient files stored in GitHub, allows authorised users to edit menu costings, and exports the results to PDF or Excel from inside WordPress.

## Features
- **GitHub-backed storage**: read and write JSON/CSV/Markdown files in a GitHub repository via the REST API (requires a personal access token).
- **Menu cost calculator**: interactive table with RM currency totals, miscellaneous percentages, and selling price comparisons.
- **PDF & Excel exports**: generate Kyros-branded PDF reports (via jsPDF) and Excel workbooks (via SheetJS) directly in the browser.
- **WordPress-native settings**: configure GitHub credentials and default menu paths from the admin Settings page.
- **Plugin-ready bundle**: the repository structure maps 1:1 to a WordPress plugin folder so it can be zipped and uploaded through the WordPress dashboard.

## Getting Started
1. Zip the project contents (for example `zip -r kyros-fnb-cost-calculator.zip .`).
2. Upload the archive through **WordPress Admin → Plugins → Add New → Upload Plugin**.
3. Activate the **Kyros F&B Cost Calculator** plugin.
4. Visit **Settings → Kyros F&B Cost Calculator** to enter your GitHub Personal Access Token, owner, repository, and default menu path.
5. Open **Kyros F&B → Cost Calculator** from the admin sidebar to load and edit your menu.

## Development Notes
- The plugin registers REST endpoints under `/wp-json/kyros-fnb/v1/` which proxy GitHub content requests using the saved credentials.
- JavaScript assets are written in vanilla ES modules and enqueue jsPDF and SheetJS from trusted CDNs.
- PDF exports are formatted for A4 portrait with Kyros Red branding (#D91C1C).

## Requirements
- WordPress 6.0+
- PHP 8.0+
- GitHub Personal Access Token with `repo` scope for private repositories (or read/write permissions for public repos).

## License
MIT
