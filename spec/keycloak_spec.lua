local _M = require 'oauth.keycloak'
local test_backend_client = require 'resty.http_ng.backend.test'

describe('Keycloak', function()
    local test_backend
    before_each(function() test_backend = test_backend_client.new() end)
    after_each(function() test_backend.verify_no_outstanding_expectations() end)

  describe('.new', function()
    it('accepts configuration', function()
        local keycloak = assert(_M.new({ endpoint = 'http://www.example.com:80/auth/realms/test', public_key = 'foobar' }))

         assert.equals('-----BEGIN PUBLIC KEY-----\nfoobar\n-----END PUBLIC KEY-----', keycloak.config.public_key)
         assert.equals('http://www.example.com:80/auth/realms/test', keycloak.config.endpoint)
         assert.equals('http://www.example.com:80/auth/realms/test/protocol/openid-connect/auth', keycloak.config.authorize_url)
         assert.equals('http://www.example.com:80/auth/realms/test/protocol/openid-connect/token', keycloak.config.token_url)
    end)

    it('works with nil public_key', function()
      local keycloak = assert(_M.new({endpoint = 'http://www.example.com:80/auth/realms/test', public_key = nil }))
      assert.equals(nil, keycloak.config.public_key)
    end)

    -- TODO: Check correct error written to logs
    it('works with nil endpoint', function()
      assert.equals(nil, _M.new())
    end)
  end)

  describe('.authorize', function()

    it('connects to keycloak', function()
        local keycloak = _M.new({ endpoint = 'http://www.example.com:80/auth/realms/test', client = test_backend })

        ngx.var = { is_args = "?", args = "client_id=foo" }
        stub(ngx.req, 'get_uri_args', function() return { response_type = 'code', client_id = 'foo', redirect_uri = 'bar' } end)


        test_backend.expect{ url = 'http://www.example.com:80/auth/realms/test/protocol/openid-connect/auth?client_id=foo' }
          .respond_with{ status = 200 , body = 'foo', headers = {} }

        stub(_M, 'respond_and_exit')
        keycloak:authorize()
        assert.spy(_M.respond_and_exit).was.called_with(200, 'foo', {})
    end)

    it('returns error when response_type missing', function()
      local keycloak = _M.new({ endpoint = 'http://www.example.com:80/auth/realms/test', client = test_backend })

      ngx.var = { is_args = "?", args = "" }
      stub(ngx.req, 'get_uri_args', function() return { client_id = 'foo', redirect_uri = 'bar' } end)

      keycloak:authorize()
      assert.spy(_M.respond_and_exit).was.called_with(400, 'invalid_request')
    end)
  end)

  describe('.get_token', function()
    it('connects to keycloak', function()
      local keycloak = _M.new({ endpoint = 'http://www.example.com:80/auth/realms/test', client = test_backend })

      ngx.var = { is_args = "?", args = "client_id=foo" }
      stub(ngx.req, 'read_body', function() return { } end)
      stub(ngx.req, 'get_post_args', function() return { grant_type = 'authorization_code', client_id = 'foo', redirect_uri = 'bar', code = 'baz'} end)

      test_backend.expect{ url = 'http://www.example.com:80/auth/realms/test/protocol/openid-connect/token'}
        .respond_with{ status = 200 , body = 'foo', headers = {} }

      stub(_M, 'respond_and_exit')
      keycloak:get_token()
      assert.spy(_M.respond_and_exit).was.called_with(200, 'foo', {})
    end)
  end)
end)