{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_12,
  nodejs,
  cargo-tauri,
  pkg-config,
  yq-go,
  lld,
  wrapGAppsHook4,
  desktop-file-utils,
  cef-obs,
  shelter,
  openssl,
  gtk3,
  libsoup_3,
  webkitgtk_4_1,
  glib-networking,
  libayatana-appindicator,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  libdrm,
  libgbm,
  libGL,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxshmfence,
  nspr,
  nss,
  pango,
  udev,
}:

let
  runtimeLibs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib-networking
    libayatana-appindicator
    libdrm
    libgbm
    libGL
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxshmfence
    nspr
    nss
    pango
    udev
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dorion";
  version = "7.0.1";

  src = fetchFromGitHub {
    owner = "SpikeHD";
    repo = "Dorion";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3GcStFkCS9BwtKzLKFqNS+qJRtGw6wfAPeoXh71zj0I=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;
  cargoHash = "sha256-/iXqviXBFN272xdnFAHV3MH4U5M2Z+k3rZozyWKvRUk=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_12;
    fetcherVersion = 5;
    hash = "sha256-3rYcKwItDgZqly2wo16/UbOtLrN23z0RN2F8tRm70yo=";
  };

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm_12
    nodejs
    cargo-tauri.hook
    pkg-config
    yq-go
    lld
    wrapGAppsHook4
    desktop-file-utils
  ];

  buildInputs = [
    openssl
    gtk3
    # tauri still links the webkit bindings on linux
    libsoup_3
    webkitgtk_4_1
    cef-obs
  ]
  ++ runtimeLibs;

  postPatch = ''
    rm -rf updater
    yq -iPo=json '.bundle.resources |= map(select(. != "updater*"))' src-tauri/tauri.conf.json

    # CEF comes from CEF_PATH, not from the bundling script
    yq -iPo=json '
      .build.beforeBundleCommand = "" | .bundle.linux.deb.files = {} | .bundle.linux.rpm.files = {}
    ' src-tauri/tauri.linux.conf.json

    ln -s ${shelter}/shelter.js src-tauri/injection/shelter.js
    ln -s "$(pwd)/src" src-tauri/html

    substituteInPlace "$cargoDepsCopy"/*/libappindicator-sys-*/src/lib.rs \
      --replace-fail "libayatana-appindicator3.so.1" "${libayatana-appindicator}/lib/libayatana-appindicator3.so.1"

    # small /dev/shm makes the CEF renderer time out
    substituteInPlace src-tauri/src/main.rs \
      --replace-fail '("--no-sandbox".into(), None),' \
        '("--no-sandbox".into(), None),
      ("--disable-dev-shm-usage".into(), None),'

    # CEF_PATH has no archive.json
    substituteInPlace "$cargoDepsCopy"/*/cef-dll-sys-*/build.rs \
      --replace-fail 'download_cef::check_archive_json(&package_version, &path.to_string_lossy())?;' ""
  '';

  doCheck = false;

  postInstall = ''
    mkdir -p "$out/lib/Dorion"
    ln -s Dorion "$out/lib/dorion"
    cp -r src-tauri/injection src "$out/lib/Dorion"

    desktop-file-edit \
      --set-comment "Tiny alternative Discord client" \
      --set-key=Exec --set-value="Dorion %U" \
      --set-key=TryExec --set-value=Dorion \
      --set-key=StartupWMClass --set-value=Dorion \
      --set-key=StartupNotify --set-value=true \
      --set-key=Categories --set-value="Network;InstantMessaging;Chat;" \
      --set-key=MimeType --set-value=x-scheme-handler/discord \
      "$out/share/applications/Dorion.desktop"
  '';

  # libcef.so is dlopen'd
  postFixup = ''
    patchelf --add-rpath "${lib.makeLibraryPath runtimeLibs}:${cef-obs}" "$out/bin/.Dorion-wrapped"
  '';

  env = {
    CI = "true";
    CEF_PATH = cef-obs;
    TAURI_RESOURCE_DIR = "${placeholder "out"}/lib";
  };

  meta = {
    description = "Tiny alternative Discord client";
    homepage = "https://github.com/SpikeHD/Dorion";
    license = lib.licenses.gpl3Only;
    mainProgram = "Dorion";
    platforms = [ "x86_64-linux" ];
  };
})
