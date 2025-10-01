<?php
/**
 * Core plugin bootstrap.
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class Kyros_FnB_Cost_Calculator {
    private static ?Kyros_FnB_Cost_Calculator $instance = null;

    private function __construct() {
        add_action( 'admin_menu', [ $this, 'register_admin_menu' ] );
        add_action( 'admin_init', [ $this, 'register_settings' ] );
        add_action( 'admin_enqueue_scripts', [ $this, 'enqueue_assets' ] );
        add_action( 'rest_api_init', [ $this, 'register_rest_routes' ] );
    }

    public static function instance(): Kyros_FnB_Cost_Calculator {
        if ( null === self::$instance ) {
            self::$instance = new self();
        }

        return self::$instance;
    }

    public function register_admin_menu(): void {
        add_menu_page(
            __( 'Kyros F&B', 'kyros-fnb' ),
            __( 'Kyros F&B', 'kyros-fnb' ),
            'manage_options',
            'kyros-fnb-cost-calculator',
            [ $this, 'render_calculator_page' ],
            'dashicons-analytics',
            58
        );

        add_submenu_page(
            'options-general.php',
            __( 'Kyros F&B Cost Calculator', 'kyros-fnb' ),
            __( 'Kyros F&B Cost Calculator', 'kyros-fnb' ),
            'manage_options',
            'kyros-fnb-settings',
            [ $this, 'render_settings_page' ]
        );
    }

    public function register_settings(): void {
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_github_owner' );
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_github_repo' );
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_github_token' );
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_menu_path' );
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_ingredients_path' );
        register_setting( 'kyros_fnb_settings', 'kyros_fnb_categories_path' );

        add_settings_section(
            'kyros_fnb_settings_section',
            __( 'GitHub Repository Settings', 'kyros-fnb' ),
            function () {
                echo '<p>' . esc_html__( 'Provide the repository details where menu, ingredient, and category files are stored.', 'kyros-fnb' ) . '</p>';
            },
            'kyros-fnb-settings'
        );

        $fields = [
            'kyros_fnb_github_owner'      => __( 'GitHub Owner/Organisation', 'kyros-fnb' ),
            'kyros_fnb_github_repo'       => __( 'GitHub Repository', 'kyros-fnb' ),
            'kyros_fnb_github_token'      => __( 'GitHub Personal Access Token', 'kyros-fnb' ),
            'kyros_fnb_menu_path'         => __( 'Default Menu Path', 'kyros-fnb' ),
            'kyros_fnb_ingredients_path'  => __( 'Ingredients Path', 'kyros-fnb' ),
            'kyros_fnb_categories_path'   => __( 'Categories Path', 'kyros-fnb' ),
        ];

        foreach ( $fields as $option => $label ) {
            add_settings_field(
                $option,
                $label,
                function () use ( $option ) {
                    $value       = esc_attr( get_option( $option, '' ) );
                    $type        = 'kyros_fnb_github_token' === $option ? 'password' : 'text';
                    $placeholder = '';
                    switch ( $option ) {
                        case 'kyros_fnb_menu_path':
                            $placeholder = 'menus/kebab.json';
                            break;
                        case 'kyros_fnb_ingredients_path':
                            $placeholder = 'data/ingredients.json';
                            break;
                        case 'kyros_fnb_categories_path':
                            $placeholder = 'data/categories.json';
                            break;
                    }
                    printf(
                        '<input type="%1$s" class="regular-text" name="%2$s" id="%2$s" value="%3$s" placeholder="%4$s" autocomplete="off" />',
                        esc_attr( $type ),
                        esc_attr( $option ),
                        $value,
                        esc_attr( $placeholder )
                    );
                },
                'kyros-fnb-settings',
                'kyros_fnb_settings_section'
            );
        }
    }

    public function render_settings_page(): void {
        if ( ! current_user_can( 'manage_options' ) ) {
            return;
        }
        ?>
        <div class="wrap">
            <h1><?php esc_html_e( 'Kyros F&B Cost Calculator Settings', 'kyros-fnb' ); ?></h1>
            <form action="options.php" method="post">
                <?php
                settings_fields( 'kyros_fnb_settings' );
                do_settings_sections( 'kyros-fnb-settings' );
                submit_button();
                ?>
            </form>
        </div>
        <?php
    }

    public function render_calculator_page(): void {
        if ( ! current_user_can( 'manage_options' ) ) {
            return;
        }
        ?>
        <div class="wrap kyros-fnb-admin">
            <h1><?php esc_html_e( 'Kyros F&B Cost Calculator', 'kyros-fnb' ); ?></h1>
            <p class="description">
                <?php esc_html_e( 'Load menu data from GitHub, adjust ingredient costs, and export Kyros-branded PDF or Excel reports.', 'kyros-fnb' ); ?>
            </p>
            <div id="kyros-fnb-app" class="kyros-fnb-app" data-menu-path="<?php echo esc_attr( get_option( 'kyros_fnb_menu_path', 'menus/kebab.json' ) ); ?>"></div>
        </div>
        <?php
    }

    public function enqueue_assets( string $hook ): void {
        if ( 'toplevel_page_kyros-fnb-cost-calculator' !== $hook ) {
            return;
        }

        wp_enqueue_style(
            'kyros-fnb-admin',
            KYROS_FNB_PLUGIN_URL . 'assets/css/admin.css',
            [],
            '1.0.0'
        );

        wp_register_script( 'kyros-fnb-jspdf', 'https://cdn.jsdelivr.net/npm/jspdf@2.5.1/dist/jspdf.umd.min.js', [], '2.5.1', true );
        wp_register_script( 'kyros-fnb-autotable', 'https://cdn.jsdelivr.net/npm/jspdf-autotable@3.8.2/dist/jspdf.plugin.autotable.min.js', [ 'kyros-fnb-jspdf' ], '3.8.2', true );
        wp_register_script( 'kyros-fnb-sheetjs', 'https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js', [], '0.18.5', true );

        wp_register_script(
            'kyros-fnb-admin',
            KYROS_FNB_PLUGIN_URL . 'assets/js/admin.js',
            [ 'wp-i18n', 'wp-element', 'wp-data', 'kyros-fnb-jspdf', 'kyros-fnb-autotable', 'kyros-fnb-sheetjs' ],
            '1.0.0',
            true
        );

        wp_localize_script(
            'kyros-fnb-admin',
            'KyrosFnbConfig',
            [
                'restUrl'        => esc_url_raw( rest_url( 'kyros-fnb/v1' ) ),
                'nonce'          => wp_create_nonce( 'wp_rest' ),
                'menuPath'       => get_option( 'kyros_fnb_menu_path', 'menus/kebab.json' ),
                'ingredientsPath'=> get_option( 'kyros_fnb_ingredients_path', 'data/ingredients.json' ),
                'categoriesPath' => get_option( 'kyros_fnb_categories_path', 'data/categories.json' ),
                'isConfigured'   => Kyros_FnB_GitHub_Client::is_configured(),
            ]
        );

        wp_enqueue_script( 'kyros-fnb-admin' );
    }

    public function register_rest_routes(): void {
        register_rest_route(
            'kyros-fnb/v1',
            '/menu',
            [
                'methods'             => WP_REST_Server::READABLE,
                'callback'            => [ $this, 'rest_get_menu' ],
                'permission_callback' => [ $this, 'ensure_capability' ],
            ]
        );

        register_rest_route(
            'kyros-fnb/v1',
            '/menu',
            [
                'methods'             => WP_REST_Server::CREATABLE,
                'callback'            => [ $this, 'rest_save_menu' ],
                'permission_callback' => [ $this, 'ensure_capability' ],
                'args'                => [
                    'content' => [
                        'required' => true,
                    ],
                    'message' => [
                        'required' => true,
                    ],
                    'sha'     => [
                        'required' => false,
                    ],
                ],
            ]
        );

        register_rest_route(
            'kyros-fnb/v1',
            '/ingredients',
            [
                'methods'             => WP_REST_Server::READABLE,
                'callback'            => [ $this, 'rest_get_ingredients' ],
                'permission_callback' => [ $this, 'ensure_capability' ],
            ]
        );

        register_rest_route(
            'kyros-fnb/v1',
            '/categories',
            [
                'methods'             => WP_REST_Server::READABLE,
                'callback'            => [ $this, 'rest_get_categories' ],
                'permission_callback' => [ $this, 'ensure_capability' ],
            ]
        );
    }

    public function ensure_capability(): bool {
        return current_user_can( 'manage_options' );
    }

    private function get_github_client(): Kyros_FnB_GitHub_Client|WP_Error {
        $token = get_option( 'kyros_fnb_github_token' );
        $owner = get_option( 'kyros_fnb_github_owner' );
        $repo  = get_option( 'kyros_fnb_github_repo' );

        if ( empty( $token ) || empty( $owner ) || empty( $repo ) ) {
            return new WP_Error( 'kyros_fnb_not_configured', __( 'GitHub credentials are not configured.', 'kyros-fnb' ) );
        }

        return new Kyros_FnB_GitHub_Client( $token, $owner, $repo );
    }

    private function load_local_data( string $file ): array {
        $path = KYROS_FNB_PLUGIN_PATH . 'assets/data/' . $file;
        if ( ! file_exists( $path ) ) {
            return [];
        }

        $raw = file_get_contents( $path );
        if ( ! $raw ) {
            return [];
        }

        $data = json_decode( $raw, true );
        return JSON_ERROR_NONE === json_last_error() ? $data : [];
    }

    public function rest_get_menu(): WP_REST_Response {
        $path = get_option( 'kyros_fnb_menu_path', 'menus/kebab.json' );
        $sha  = null;
        $data = null;

        $client = $this->get_github_client();
        if ( ! is_wp_error( $client ) ) {
            $response = $client->get_file( $path );
            if ( ! is_wp_error( $response ) && isset( $response['content'] ) ) {
                $decoded = base64_decode( $response['content'] );
                if ( false !== $decoded ) {
                    $data = json_decode( $decoded, true );
                    if ( JSON_ERROR_NONE === json_last_error() ) {
                        $sha = $response['sha'] ?? null;
                    }
                }
            }
        }

        if ( null === $data ) {
            $data = $this->load_local_data( 'menu.json' );
        }

        return new WP_REST_Response(
            [
                'menu' => $data,
                'sha'  => $sha,
            ]
        );
    }

    public function rest_save_menu( WP_REST_Request $request ) {
        $client = $this->get_github_client();
        if ( is_wp_error( $client ) ) {
            return $client;
        }

        $content = $request->get_param( 'content' );
        $message = $request->get_param( 'message' );
        $sha     = $request->get_param( 'sha' );
        $path    = get_option( 'kyros_fnb_menu_path', 'menus/kebab.json' );

        $encoded = wp_json_encode( $content, JSON_PRETTY_PRINT );
        if ( false === $encoded ) {
            return new WP_Error( 'kyros_fnb_encode_error', __( 'Unable to encode menu content as JSON.', 'kyros-fnb' ) );
        }

        $result = $client->put_file( $path, $encoded, $message, $sha ? (string) $sha : null );

        if ( is_wp_error( $result ) ) {
            return $result;
        }

        return new WP_REST_Response( $result );
    }

    public function rest_get_ingredients(): WP_REST_Response {
        $path = get_option( 'kyros_fnb_ingredients_path', 'data/ingredients.json' );
        $data = null;

        $client = $this->get_github_client();
        if ( ! is_wp_error( $client ) ) {
            $response = $client->get_file( $path );
            if ( ! is_wp_error( $response ) && isset( $response['content'] ) ) {
                $decoded = base64_decode( $response['content'] );
                if ( false !== $decoded ) {
                    $data = json_decode( $decoded, true );
                }
            }
        }

        if ( null === $data ) {
            $data = $this->load_local_data( 'ingredients.json' );
        }

        return new WP_REST_Response( [ 'ingredients' => $data ] );
    }

    public function rest_get_categories(): WP_REST_Response {
        $path = get_option( 'kyros_fnb_categories_path', 'data/categories.json' );
        $data = null;

        $client = $this->get_github_client();
        if ( ! is_wp_error( $client ) ) {
            $response = $client->get_file( $path );
            if ( ! is_wp_error( $response ) && isset( $response['content'] ) ) {
                $decoded = base64_decode( $response['content'] );
                if ( false !== $decoded ) {
                    $data = json_decode( $decoded, true );
                }
            }
        }

        if ( null === $data ) {
            $data = $this->load_local_data( 'categories.json' );
        }

        return new WP_REST_Response( [ 'categories' => $data ] );
    }
}
