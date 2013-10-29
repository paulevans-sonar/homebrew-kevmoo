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
  homepage 'http://www.dartlang.org/'
  url 'https://gsdview.appspot.com/dart-editor-archive-integration/29341/darteditor-macos-64.zip'
  version '29341'
  sha1 '4e00d1257266831c9c2b307da6583dcbe6abfe65'

  devel do
    url 'https://gsdview.appspot.com/dart-editor-archive-trunk/29341/darteditor-macos-64.zip'
    version '29341'
    sha1 '90c3dc3ef18710e6ab94c89067c19a5195d95dc4'
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

    item = Dir[prefix+'chromium/Content Shell.app/Contents/MacOS/Content Shell']
    (bin+'content_shell').write shim_script(item)

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
