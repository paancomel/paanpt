<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Export {
    public static function sop_link(int $recipe_id): string {
        return add_query_arg(array('krm_sop' => $recipe_id), home_url('/'));
    }
}
