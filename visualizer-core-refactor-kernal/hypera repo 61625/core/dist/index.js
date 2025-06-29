"use strict";
/**
 * @parserator/core
 * Shared HTTP client and utilities for Parserator SDK ecosystem
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = exports.createParseClient = exports.ParseClient = void 0;
// Re-export types for convenience
__exportStar(require("@parserator/types"), exports);
// Core client
var client_1 = require("./client");
Object.defineProperty(exports, "ParseClient", { enumerable: true, get: function () { return client_1.ParseClient; } });
Object.defineProperty(exports, "createParseClient", { enumerable: true, get: function () { return client_1.createParseClient; } });
// Default export
var client_2 = require("./client");
Object.defineProperty(exports, "default", { enumerable: true, get: function () { return client_2.ParseClient; } });
//# sourceMappingURL=index.js.map