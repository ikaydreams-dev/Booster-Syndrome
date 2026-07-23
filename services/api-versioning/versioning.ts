import { Request, Response, NextFunction } from 'express';

export enum ApiVersion {
  V1 = 'v1',
  V2 = 'v2',
  V3 = 'v3',
}

export interface VersionedRoute {
  version: ApiVersion;
  handler: (req: Request, res: Response, next: NextFunction) => void;
}

export class ApiVersionManager {
  private routes: Map<string, Map<ApiVersion, VersionedRoute>>;
  private defaultVersion: ApiVersion;

  constructor(defaultVersion: ApiVersion = ApiVersion.V1) {
    this.routes = new Map();
    this.defaultVersion = defaultVersion;
  }

  registerRoute(path: string, route: VersionedRoute): void {
    if (!this.routes.has(path)) {
      this.routes.set(path, new Map());
    }

    this.routes.get(path)!.set(route.version, route);
  }

  getHandler(path: string, version?: ApiVersion) {
    const pathRoutes = this.routes.get(path);

    if (!pathRoutes) {
      return null;
    }

    const targetVersion = version || this.defaultVersion;
    return pathRoutes.get(targetVersion)?.handler || null;
  }

  versionMiddleware() {
    return (req: Request, res: Response, next: NextFunction) => {
      const version = this.extractVersion(req);

      if (!this.isValidVersion(version)) {
        return res.status(400).json({
          error: 'Invalid API version',
          supportedVersions: Object.values(ApiVersion),
        });
      }

      req.apiVersion = version;
      next();
    };
  }

  private extractVersion(req: Request): ApiVersion {
    const headerVersion = req.headers['api-version'] as string;
    if (headerVersion && this.isValidVersion(headerVersion)) {
      return headerVersion as ApiVersion;
    }

    const pathMatch = req.path.match(/^\/(v\d+)\//);
    if (pathMatch && this.isValidVersion(pathMatch[1])) {
      return pathMatch[1] as ApiVersion;
    }

    const queryVersion = req.query.version as string;
    if (queryVersion && this.isValidVersion(queryVersion)) {
      return queryVersion as ApiVersion;
    }

    return this.defaultVersion;
  }

  private isValidVersion(version: string): boolean {
    return Object.values(ApiVersion).includes(version as ApiVersion);
  }
}

declare global {
  namespace Express {
    interface Request {
      apiVersion?: ApiVersion;
    }
  }
}

export function deprecationWarning(
  deprecatedVersion: ApiVersion,
  sunsetDate: Date
) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.apiVersion === deprecatedVersion) {
      res.setHeader('Deprecation', 'true');
      res.setHeader('Sunset', sunsetDate.toISOString());
      res.setHeader(
        'Link',
        '</docs/migration>; rel="deprecation"; type="text/html"'
      );
    }
    next();
  };
}
