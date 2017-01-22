MRuby::Gem::Specification.new('mruby-http2') do |spec|
  spec.license = 'MIT'
  spec.authors = 'MATSUMOTO Ryosuke'
  spec.version = '0.0.1'
  spec.summary = 'HTTP/2 Client and Server Module'

  if !ENV['VisualStudioVersion'] && !ENV['VSINSTALLDIR']
  spec.linker.libraries << ['ssl', 'crypto', 'z', 'event', 'event_openssl', 'curl']
  else
  spec.linker.libraries << ['libssl', 'libcrypto', 'zlibd', 'event','nghttp2', 'Advapi32']
  spec.linker.flags = "/nodefaultlib:msvcrtd"
  end
  
  spec.add_dependency('mruby-simplehttp')
  spec.cc.flags << "-DMRB_HTTP2_TRACER=1"
  if RUBY_PLATFORM =~ /darwin/i
    spec.cc.flags << "-I/usr/local/include"
    spec.linker.library_paths << "/usr/local/lib"
  end

  require 'open3'

  nghttp2_dir = "#{build_dir}/nghttp2"
  nghttp2_lib = "#{build_dir}/nghttp2/lib/.libs"
  libnghttp2a = "#{nghttp2_lib}/libnghttp2.a"
  if ENV['NGHTTP2_CURRENT'] != "true"
    nghttp2_ver = "894c1bd02ed71be5f684653d27749de541226f6f"
  end

  def run_command env, command
    STDOUT.sync = true
    puts "mruby-http2 build: [exec] #{command}"
    Open3.popen2e(env, command) do |stdin, stdout, thread|
      print stdout.read
      fail "#{command} failed" if thread.value != 0
    end
  end

  FileUtils.mkdir_p build_dir
  
  if !ENV['VisualStudioVersion'] && !ENV['VSINSTALLDIR']
  if ! File.exists? nghttp2_dir
    Dir.chdir(build_dir) do
    e = {}
      run_command e, 'git clone https://github.com/nghttp2/nghttp2.git'
    end
  end
  
  if ! File.exists? libnghttp2a
    Dir.chdir nghttp2_dir do
      e = {}
    if ENV['NGHTTP2_CURRENT'] != "true"
      run_command e, "git checkout #{nghttp2_ver} ."
    end
      run_command e, 'git submodule init'
      run_command e, 'git submodule update'
      run_command e, 'autoreconf -i'
      run_command e, 'automake'
      run_command e, 'autoconf'
      if RUBY_PLATFORM =~ /darwin/i
        run_command e, './configure --enable-app --disable-threads --enable-shared=no'
      else
        run_command e, './configure --enable-app --enable-shared=no CFLAGS="-g -O2 -fPIC"'
      end
      run_command e, 'make'
    end
  end

  spec.cc.include_paths << "#{nghttp2_dir}/lib/includes"
  spec.linker.flags_before_libraries << libnghttp2a
  end 
end

