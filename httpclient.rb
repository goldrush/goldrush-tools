require 'rubygems'
require 'httpclient'

def main
  # 第一引数はURL
  url = ARGV.shift
  # 第二引数以降、key=value形式でパラメータが渡される形式
  params = {}
  ARGV.each do |arg|
    pr = str_to_hash(arg)
    params.merge! str_to_hash(arg)
  end
  # パラメータにSTDIN=[パラメータ名]とあったらSTDINからの入力をパラメータとして渡すモード
  if params['STDIN'] != nil
    params[params['STDIN'].to_s.strip] = STDIN.read
  end
  
  # httpclientを利用したサーバー呼び出し
  around_http_client do |agent|
    res = agent.post url, params
    if res.status_code != 200
      File.open(File.join('log',"errmail","http_client_call.#{Time.now.strftime('%Y%m%d_%H%M%S')}.#{Process.pid}.log"), "a") do |file|
        file.puts res.inspect
      end
    end
  end
end

def around_http_client(&block)
  # HTTP Clientの準備
  api_logfile = File.open(File.join('log',"mail","http_client_call.#{Time.now.strftime('%Y%m%d_%H%M%S')}.#{Process.pid}.log"), "a")
  agent = HTTPClient.new
  agent.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
  agent.receive_timeout = 300
#  agent.debug_dev = STDOUT
  agent.debug_dev = api_logfile
  3.times do |x|
    begin
      block.call agent
      break
    rescue SocketError => e
      STDERR.puts "SocketError #{x+1} times."
      sleep 1
    end
  end
ensure
  agent.debug_dev = nil
  api_logfile.close
end

def str_to_hash(str, separator="=")
  k,v = str.split(separator)
  return {k.to_s.strip => v.to_s.strip}
end

main
