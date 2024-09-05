/**
 * Validates if the given string is a valid PostgreSQL URL.
 * @param url The URL to validate
 * @returns boolean indicating if the URL is valid
 */
export function isValidPostgresURL(url: string): boolean {
    // Regular expression to match PostgreSQL URL format
    const postgresURLRegex = /^postgresql:\/\/(?:([^:@]+)(?::([^@]+))?@)?([^:@/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/;
  
    // Test the input URL against the regex
    const match = url.match(postgresURLRegex);
  
    if (!match) {
      return false;
    }
  
    // Destructure the matched groups
    const [, user, password, host, port, dbname, params] = match;
  
    // Additional checks
    if (port && (parseInt(port) <= 0 || parseInt(port) > 65535)) {
      return false; // Invalid port number
    }
  
    if (host.length === 0) {
      return false; // Host is required
    }
  
    return true;
  }

export function parsePostgresURL(url: string): {
        database: string;
        hostname: string;
        port: number | null;
        username: string;
        password: string;
        ssl: string | null;
      } {
        const regex = /^postgresql:\/\/(?:([^:@]+)(?::([^@]+))?@)?([^:@/?]+)(?::(\d+))?(?:\/([^?]+))?(?:\?(.+))?$/;
        const match = url.match(regex);
      
        if (!match) {
          throw new Error("Invalid PostgreSQL URL");
        }
      
        const [, username, password, hostname, port, database, queryString] = match;
      
        const params = new URLSearchParams(queryString || "");
        const ssl = params.get("sslmode");
      
        return {
          database: database || "",
          hostname: hostname,
          port: port ? parseInt(port) : null,
          username: username || "",
          password: password || "",
          ssl: ssl
  };
}