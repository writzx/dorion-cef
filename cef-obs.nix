{
  lib,
  cef-binary,
  fetchurl,
  libpulseaudio,
  libva,
  pipewire,
}:

# Laid out as cef-dll-sys expects at CEF_PATH: Release/ and Resources/
# flattened, with include/.
cef-binary.overrideAttrs (oldAttrs: {
  pname = "cef-obs";
  # OBS 33.0.1, branch 7871
  version = "150.0.19";

  src = fetchurl {
    url = "https://cdn-fastly.obsproject.com/downloads/cef_binary_7871_linux_x86_64.tar.xz";
    hash = "sha256-j/xk0G6nTaYT7tp/KqXU6YZhr2+j7Yxockyabk6J6o4=";
  };

  postInstall = ''
    find "$out" -mindepth 1 -delete
    mv Release/* Resources/* include "$out"/
    find "$out/locales" -type f ! -name en-US.pak -delete
  '';

  stripDebugList = [ "." ];

  # dlopen'd by libcef.so
  postFixup = ''
    patchelf --add-rpath "${
      lib.makeLibraryPath [
        libpulseaudio
        pipewire
        libva
      ]
    }" "$out/libcef.so"
  '';

  meta = oldAttrs.meta // {
    platforms = [ "x86_64-linux" ];
  };
})
