class Zeek < Formula
  desc "Network security monitor"
  homepage "https://www.zeek.org"
  url "https://github.com/zeek/zeek.git",
      tag:      "v4.1.0",
      revision: "73783cc8a62017835208b54753dd69ea5667ef2f"
  license "BSD-3-Clause"
  head "https://github.com/zeek/zeek.git"

  bottle do
    sha256 arm64_big_sur: "7e26e7bef14bbfb5a198f618b53c9985c2f3f9059fd367238bc69f5dabf8e880"
    sha256 big_sur:       "f495915276550ecc000d756466c923f9b59714e71b2ba27eed56c6918985f558"
    sha256 catalina:      "964022f5acec17e81d4ccac974a01bb07c5623af24046a15a11fcb696b6d9bbc"
    sha256 mojave:        "0d21a26a3785f6d3b34cefbf57273251a442d2ad2c53a1d0672ffdbe0d39404a"
    sha256 x86_64_linux:  "2744c426f2b90b03919aa1b112ec19bcf0d30ebfe32f2ac1a813bc5af19db455"
  end

  depends_on "bison" => :build
  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "caf"
  depends_on "geoip"
  depends_on "libmaxminddb"
  depends_on macos: :mojave
  depends_on "openssl@1.1"
  depends_on "python@3.9"

  uses_from_macos "flex"
  uses_from_macos "libpcap"
  uses_from_macos "zlib"

  on_linux do
    depends_on "gcc" # For C++17
  end

  fails_with gcc: "5"

  def install
    # Remove SDK paths from zeek-config. This breaks usage with other SDKs.
    # https://github.com/corelight/zeek-community-id/issues/15
    inreplace "zeek-config.in" do |s|
      s.gsub! "@ZEEK_CONFIG_PCAP_INCLUDE_DIR@", ""
      s.gsub! "@ZEEK_CONFIG_ZLIB_INCLUDE_DIR@", ""
    end

    mkdir "build" do
      system "cmake", "..", *std_cmake_args,
                      "-DBROKER_DISABLE_TESTS=on",
                      "-DBUILD_SHARED_LIBS=on",
                      "-DINSTALL_AUX_TOOLS=on",
                      "-DINSTALL_ZEEKCTL=on",
                      "-DUSE_GEOIP=on",
                      "-DCAF_ROOT=#{Formula["caf"].opt_prefix}",
                      "-DOPENSSL_ROOT_DIR=#{Formula["openssl@1.1"].opt_prefix}",
                      "-DZEEK_ETC_INSTALL_DIR=#{etc}",
                      "-DZEEK_LOCAL_STATE_DIR=#{var}"
      system "make", "install"
    end
  end

  test do
    assert_match "version #{version}", shell_output("#{bin}/zeek --version")
    assert_match "ARP packet analyzer", shell_output("#{bin}/zeek --print-plugins")
    system bin/"zeek", "-C", "-r", test_fixtures("test.pcap")
    assert_predicate testpath/"conn.log", :exist?
    refute_predicate testpath/"conn.log", :empty?
    assert_predicate testpath/"http.log", :exist?
    refute_predicate testpath/"http.log", :empty?
    # For bottling MacOS SDK paths must not be part of the public include directories, see zeek/zeek#1468.
    refute_includes shell_output("#{bin}/zeek-config --include_dir").chomp, "MacOSX"
  end
end
