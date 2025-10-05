<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

class Roles {
    public static function add_roles() {
        add_role('krm_admin', 'KRM Admin', array('read' => true, 'manage_options' => true));
        add_role('krm_operation', 'KRM Operation', array('read' => true));
        add_role('krm_supervisor', 'KRM Supervisor', array('read' => true));
    }

    public static function remove_roles() {
        remove_role('krm_admin');
        remove_role('krm_operation');
        remove_role('krm_supervisor');
    }

    public static function add_caps() {
        $caps = array(
            'read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient',
            'read_recipe','edit_recipe','edit_recipes','publish_recipes','delete_recipe',
            'krm_manage_settings','krm_export_pdf','krm_mention_user','krm_approve_recipe'
        );

        if ($role = get_role('administrator')) foreach ($caps as $c) { $role->add_cap($c); }
        if ($role = get_role('krm_admin'))     foreach ($caps as $c) { $role->add_cap($c); }
        if ($role = get_role('krm_operation')) {
            foreach (array('read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient','read_recipe','edit_recipe','edit_recipes','publish_recipes') as $c) {
                $role->add_cap($c);
            }
        }
        if ($role = get_role('krm_supervisor')) {
            foreach (array('read_ingredient','read_recipe') as $c) { $role->add_cap($c); }
        }
    }

    public static function remove_caps() {
        $all_roles = array('administrator','krm_admin','krm_operation','krm_supervisor');
        $caps = array(
            'read_ingredient','edit_ingredient','edit_ingredients','publish_ingredients','delete_ingredient',
            'read_recipe','edit_recipe','edit_recipes','publish_recipes','delete_recipe',
            'krm_manage_settings','krm_export_pdf','krm_mention_user','krm_approve_recipe'
        );
        foreach ($all_roles as $r) {
            if ($role = get_role($r)) { foreach ($caps as $c) { $role->remove_cap($c); } }
        }
    }
}
