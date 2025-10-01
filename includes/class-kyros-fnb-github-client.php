<?php
/**
 * GitHub client helper for Kyros F&B Cost Calculator.
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

class Kyros_FnB_GitHub_Client {
    private string $token;
    private string $owner;
    private string $repo;

    public function __construct( string $token, string $owner, string $repo ) {
        $this->token = $token;
        $this->owner = $owner;
        $this->repo  = $repo;
    }

    public static function is_configured(): bool {
        return (bool) get_option( 'kyros_fnb_github_token' ) &&
            (bool) get_option( 'kyros_fnb_github_owner' ) &&
            (bool) get_option( 'kyros_fnb_github_repo' );
    }

    private function api_base(): string {
        return sprintf( 'https://api.github.com/repos/%s/%s/contents/', rawurlencode( $this->owner ), rawurlencode( $this->repo ) );
    }

    /**
     * Perform a request against the GitHub contents API.
     *
     * @throws WP_Error on failure.
     */
    private function request( string $method, string $path, array $body = [] ) {
        $url  = trailingslashit( $this->api_base() ) . ltrim( $path, '/' );
        $args = [
            'method'  => $method,
            'headers' => [
                'Authorization' => 'token ' . $this->token,
                'Content-Type'  => 'application/json',
                'Accept'        => 'application/vnd.github+json',
                'User-Agent'    => 'kyros-fnb-cost-calculator',
            ],
        ];

        if ( ! empty( $body ) ) {
            $args['body'] = wp_json_encode( $body );
        }

        $response = wp_remote_request( $url, $args );

        if ( is_wp_error( $response ) ) {
            return $response;
        }

        $code = wp_remote_retrieve_response_code( $response );
        if ( $code < 200 || $code >= 300 ) {
            return new WP_Error( 'kyros_fnb_github_error', __( 'GitHub API request failed.', 'kyros-fnb' ), [
                'status'   => $code,
                'response' => wp_remote_retrieve_body( $response ),
            ] );
        }

        $data = json_decode( wp_remote_retrieve_body( $response ), true );
        if ( JSON_ERROR_NONE !== json_last_error() ) {
            return new WP_Error( 'kyros_fnb_json_error', __( 'Invalid JSON returned from GitHub.', 'kyros-fnb' ) );
        }

        return $data;
    }

    /**
     * Retrieve file contents and metadata from GitHub.
     */
    public function get_file( string $path ) {
        return $this->request( 'GET', $path );
    }

    /**
     * Create or update a file on GitHub.
     */
    public function put_file( string $path, string $content, string $message, ?string $sha = null ) {
        $body = [
            'message' => $message,
            'content' => base64_encode( $content ),
        ];

        if ( $sha ) {
            $body['sha'] = $sha;
        }

        return $this->request( 'PUT', $path, $body );
    }
}
