const fs = require("fs");
const path = require("path");

const { withXcodeProject } = require("@expo/config-plugins");

const IMPORT_LINE = "#import <React/RCTBridge.h>";

function stripSurroundingQuotes(value) {
  if (typeof value !== "string") return value;
  const trimmed = value.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function getIOSRoot(modRequest) {
  return modRequest?.platformProjectRoot || path.join(modRequest.projectRoot, "ios");
}

function findXcodeProjectName(iosRoot) {
  // Prefer <name>.xcodeproj in the ios root
  const entries = fs.existsSync(iosRoot) ? fs.readdirSync(iosRoot) : [];
  const xcodeproj = entries.find((e) => e.endsWith(".xcodeproj"));
  if (!xcodeproj) return null;
  return path.basename(xcodeproj, ".xcodeproj");
}

function ensureImportInBridgingHeader(absolutePath) {
  let contents = "";
  if (fs.existsSync(absolutePath)) {
    contents = fs.readFileSync(absolutePath, "utf8");
  } else {
    // Ensure parent folder exists
    fs.mkdirSync(path.dirname(absolutePath), { recursive: true });
    contents = "//\n//  Bridging Header\n//\n\n";
  }

  if (!contents.includes(IMPORT_LINE)) {
    const next = contents.replace(/\s*$/, "") + "\n" + IMPORT_LINE + "\n";
    fs.writeFileSync(absolutePath, next);
  }
}

function getBuildConfigurations(project) {
  const section = project.pbxXCBuildConfigurationSection();
  return Object.entries(section)
    .filter(([key, value]) => key.endsWith("_comment") === false && value && typeof value === "object")
    .map(([, value]) => value);
}

function isAppLikeBuildSettings(buildSettings) {
  if (!buildSettings || typeof buildSettings !== "object") return false;
  // Heuristic: app targets typically define an Info.plist and bundle id.
  return Boolean(buildSettings.INFOPLIST_FILE || buildSettings.PRODUCT_BUNDLE_IDENTIFIER);
}

function getExistingBridgingHeaderPath(project) {
  for (const cfg of getBuildConfigurations(project)) {
    const bs = cfg.buildSettings;
    if (!isAppLikeBuildSettings(bs)) continue;
    if (bs.SWIFT_OBJC_BRIDGING_HEADER) {
      // node-xcode may return the quotes as part of the value, so normalize it.
      return stripSurroundingQuotes(bs.SWIFT_OBJC_BRIDGING_HEADER);
    }
  }
  return null;
}

function setBridgingHeaderPathForAppConfigs(project, relativePath) {
  for (const cfg of getBuildConfigurations(project)) {
    const bs = cfg.buildSettings;
    if (!isAppLikeBuildSettings(bs)) continue;
    bs.SWIFT_OBJC_BRIDGING_HEADER = relativePath;
  }
}

/**
 * @type {import("@expo/config-plugins").ConfigPlugin}
 */
const withComergeRuntime = (config) => {
  return withXcodeProject(config, (cfg) => {
    const iosRoot = getIOSRoot(cfg.modRequest);
    const project = cfg.modResults;

    // Use existing bridging header if present; otherwise create a new one.
    let rel = stripSurroundingQuotes(getExistingBridgingHeaderPath(project));
    if (!rel) {
      const projectName = findXcodeProjectName(iosRoot);
      if (projectName) {
        rel = `${projectName}/${projectName}-Bridging-Header.h`;
      } else {
        rel = "ComergeRuntime-Bridging-Header.h";
      }
      setBridgingHeaderPathForAppConfigs(project, rel);
    }

    // Ensure the file exists and contains the needed import.
    rel = stripSurroundingQuotes(rel);
    const abs = path.isAbsolute(rel) ? rel : path.join(iosRoot, rel);
    ensureImportInBridgingHeader(abs);

    return cfg;
  });
};

module.exports = withComergeRuntime;
module.exports.withComergeRuntime = withComergeRuntime;


