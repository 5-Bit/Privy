## Privy Web Service Documentation

This api is hosted at [privyapp.com](https://privyapp.com).

## Users

To create a user, call the `/users/new` route with a form that has a `username`, `email`, and `password`
Any errors will be reported in the `Privy-api-error` response header 
You will get back a JSON object with the following layout if no errors occur:

```JSON
{
  "UserId": 1,
  "Session": "df43wdsff132423d"
}
```

## Routes to Categorize

```go
    router.GET("/verify/:verifyToken", verifyUser)

    // TODO:  Fix these routes
    // end routes that need fixing

    router.PUT("/users/id/:id", userByID)
    router.GET("/users/handle/:user", searchUsers)
    router.POST("/users/new", newUser)
    router.PUT("/users/auth", authUser)
    router.PUT("/users/logout", invalidateSession)
    router.GET("/", index)
```
