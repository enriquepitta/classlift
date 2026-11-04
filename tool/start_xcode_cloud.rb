#!/usr/bin/env ruby
require 'base64'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

workflow_id = 'BD005DA6-FC4C-4300-A4FC-4E7DBD67A661'
key_id = ENV.fetch('ASC_KEY_ID')
issuer = ENV.fetch('ASC_ISSUER_ID')
key = OpenSSL::PKey.read(ENV.fetch('ASC_PRIVATE_KEY'))
branch = ENV.fetch('CLASSLIFT_SOURCE_BRANCH')
raise 'Faltan las credenciales de App Store Connect.' if [key_id, issuer, branch].any?(&:empty?)
raise 'La clave debe ser EC P-256.' unless key.is_a?(OpenSSL::PKey::EC) && key.group.curve_name == 'prime256v1'

encode = ->(value) { Base64.urlsafe_encode64(value, padding: false) }
now = Time.now.to_i
header = encode.call(JSON.generate(alg: 'ES256', kid: key_id, typ: 'JWT'))
claims = encode.call(JSON.generate(iss: issuer, iat: now - 30, exp: now + 600, aud: 'appstoreconnect-v1'))
input = "#{header}.#{claims}"
der = key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(input))
signature = OpenSSL::ASN1.decode(der).value.map { |part| part.value.to_s(16).rjust(64, '0') }.join
token = "#{input}.#{encode.call([signature].pack('H*'))}"

request = lambda do |path, payload = nil|
  uri = URI.join('https://api.appstoreconnect.apple.com', path)
  raise 'Destino API inesperado.' unless uri.scheme == 'https' && uri.host == 'api.appstoreconnect.apple.com'
  req = payload ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{token}"
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate(payload) if payload
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 60) { |http| http.request(req) }
  raise "App Store Connect respondió HTTP #{response.code}." unless response.is_a?(Net::HTTPSuccess)
  JSON.parse(response.body)
end

workflow = request.call("/v1/ciWorkflows/#{workflow_id}").fetch('data')
raise 'El workflow está desactivado.' unless workflow.dig('attributes', 'isEnabled')
repo = workflow.dig('relationships', 'repository', 'data', 'id')
repo ||= request.call(workflow.dig('relationships', 'repository', 'links', 'related')).dig('data', 'id')
raise 'No se encontró el repositorio del workflow.' unless repo
path = "/v1/scmRepositories/#{repo}/gitReferences?limit=200"
ref = nil
while path && !ref
  page = request.call(path)
  ref = page.fetch('data').find { |item| item.dig('attributes', 'canonicalName') == "refs/heads/#{branch}" && !item.dig('attributes', 'isDeleted') }
  path = page.dig('links', 'next')
end
raise 'Apple todavía no encuentra la rama indicada.' unless ref
payload = { data: { type: 'ciBuildRuns', attributes: { clean: false }, relationships: {
  workflow: { data: { type: 'ciWorkflows', id: workflow_id } },
  sourceBranchOrTag: { data: { type: 'scmGitReferences', id: ref.fetch('id') } }
} } }
run = request.call('/v1/ciBuildRuns', payload).fetch('data')
puts "Compilación #{run.dig('attributes', 'number')} iniciada en Xcode Cloud: #{run.fetch('id')}."
puts 'El inicio no confirma que la compilación esté disponible en TestFlight.'
