# Running APIcast with RH-SSO for OIDC


## Client Registration

In order to authenticate clients in RH SSO and correctly track usage in 3scale, client credentials need to be synchronised between the 2 systems. Typically this functionality would fall outside the realm of the Gateway, but we will show how you can implement this within the Gateway to provide a self contained environment. 

We will use the same approach as in the Custom Configuration example to add an additional server block to handle the client registration in RH SSO. In this case, clients will be created in 3scale first and imported into RH SSO. 

The way to do this is in docker would be by mounting a volume inside `sites.d` folder in the container.

Additionally we need to add some additional code to deal with client registration webhooks. This is included in `webhook-handler.lua`

Altogether these 2 files would be mounted as follows: 

```shell
docker run --publish 8080:8080 --volume $(pwd)/rh-sso.conf:/opt/app/sites.d/rh-sso.conf --volume $(pwd)/client-registrations:/opt/app/src/client-registrations --env-file $(pwd)/.env --env RHSSO_ENDPOINT=https://{rh-sso-host}:{port}/auth/realms/{your-realm} --env THREESCALE_PORTAL_ENDPOINT=http://portal.example.com quay.io/3scale/apicast:master
```

If you're running natively, you can just add these files directly into `apicast/sites.d` and `apicast/src` respectively.


