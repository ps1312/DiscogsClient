### Contracts

#### Search artist response

```json
{
  "pagination": {
    "page": 1,
    "pages": 5,
    "per_page": 30,
    "items": 300
  },
  "results": [
    {
      "id": 1,
      "title": "Nirvana",
      "thumb": "https://i.discogs.com/id?params.jpeg" // optional
    }
  ]
}
```

#### Artist details response

```json
{
  "id": 123,
  "name": "Red Hot Chili Peppers",
  "profile": "description of the artist", // optional
  "images": [
    {
      "type": "primary",
      "uri": "https://i.discogs.com/id?params.jpeg"
    }
  ],
  "members": [
    // optional
    {
      "name": "John Frusciante",
      "active": true
    }
  ]
}
```

#### Artist releases

```json
{
  "pagination": {
    "page": 1,
    "pages": 5,
    "per_page": 30,
    "items": 300
  },
  "results": [
    {
      "id": 1,
      "title": "By The Way",
      "label": "Label Records", // optional
      "format": "can have Album", // optional
      "year": 1986,
      "thumb": "https://i.discogs.com/id?params.jpeg" // optional
    }
  ]
}
```
