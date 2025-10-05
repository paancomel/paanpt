<?php
namespace Kyros\RecipeManager;

defined('ABSPATH') || exit;

/** Lightweight calculator utilities */
class Calculator {
    /** Row subtotal: qty * unit_cost * (1 + waste/100) */
    public static function row_subtotal(float $qty, float $unit_cost, float $waste_pct = 0.0): float {
        return round((float)$qty * (float)$unit_cost * (1 + ((float)$waste_pct/100)), 4);
    }

    public static function total(array $rows): float {
        $t = 0.0;
        foreach ($rows as $r) { $t += self::row_subtotal((float)($r['quantity']??0), (float)($r['unit_cost']??0), (float)($r['waste_pct']??0)); }
        return round($t, 4);
    }

    public static function misc_amount(float $total, float $misc_pct): float {
        return round($total * ((float)$misc_pct/100), 4);
    }

    public static function cost_percent(float $total, float $selling): float {
        if ($selling <= 0) return 0.0;
        return round(($total / $selling) * 100, 2);
    }
}
