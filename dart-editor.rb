require 'formula'

class Requires64Bit < Requirement
  def message
    "Requires 64-bit OS"
  end

  def satisfied?
    MacOS.prefer_64_bit?
  end

  def fatal?
    true
  end
end

class RequiresNoDart < Requirement
  def message
    <<-EOS.undent
    You must uninstall the 'dart' formula before continuing.
    This formula includes a superset of the functionality in 'dart'.
    EOS
  end

  def satisfied?
    not Formula.factory('dart').installed?
  end

  def fatal?
    true
  end
end

class DartEditor < Formula
  VERSION = '30036'
  BASE_URL = "https://gsdview.appspot.com/dart-archive/channels/stable/release/#{VERSION}/"

  homepage 'http://www.dartlang.org/'
  url "#{BASE_URL}editor/darteditor-macos-x64.zip"
  version VERSION
  sha1 '323c5a51689322765c86715c453c4709485dee47'

  option 'with-content-shell', 'Download and install content_shell -- headless Chromium for testing'

  resource 'content_shell' do
    url "#{BASE_URL}dartium/content_shell-macos-ia32-release.zip"
    sha1 'a915a408ca76d1e74b5684b6f3f60feb331221e7'
  end

  depends_on Requires64Bit
  depends_on RequiresNoDart

  def shim_script target
    <<-EOS.undent
      #!/bin/bash
      export DART_SDK=#{prefix}/dart-sdk
      exec "#{target}" "$@"
    EOS
  end

  def install
    prefix.install Dir['*']

    items = Dir[prefix+'dart-sdk/bin/*'].select { |f| File.file? f }

    items.each do |item|
      name = File.basename item
      (bin+name).write shim_script(item)
    end

    if build.with? 'content-shell'
      content_shell_path = prefix+'chromium/content_shell'
      (content_shell_path).install resource('content_shell')

      puts content_shell_path

      item = Dir["#{content_shell_path}/Content Shell.app/Contents/MacOS/Content Shell"]

      (bin+'content_shell').write shim_script(item)

    end

  end

  def caveats; <<-EOS.undent
    DartEditor.app was installed in:
      #{installed_prefix}

    To symlink into ~/Applications, you can do:
      brew linkapps
    EOS
  end

  def test
    mktemp do
      (Pathname.pwd+'sample.dart').write <<-EOS.undent
      import 'dart:io';
      void main() {
        Options opts = new Options();
        if(opts.arguments.length == 1 && opts.arguments[0] == 'test message') {
          exit(0);
        } else {
          exit(1);
        }
      }
      EOS

      system "#{bin}/dart sample.dart 'test message'"
    end
  end
end
