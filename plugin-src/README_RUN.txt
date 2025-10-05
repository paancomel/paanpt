# How to run

1) Save this script as generate_plugin.sh
2) Run: bash generate_plugin.sh
3) Copy the generated folder "kyros-recipe-manager-Farhan/" into your WordPress "wp-content/plugins/" directory.
4) In WP Admin → Plugins, activate **Kyros Recipe Manager By Farhan**.
5) Go to **Recipe Ops → Settings** to set currency (MYR), unit system, misc %, allergens.
6) Create **Ingredients** with base unit, price per base, supplier & allergens.
7) Create a **Recipe**, then view the front-end with shortcode:
   [recipe_calculator id="RECIPE_ID"]
   or add the **Recipe Calculator** block.
8) Use **Save Menu** to persist line items; print the SOP using the browser print dialog.

Notes:
- This is an MVP scaffold with secure defaults. Improve UI/UX and add PDF engine later if needed.
