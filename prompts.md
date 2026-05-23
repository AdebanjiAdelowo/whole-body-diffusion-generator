# Prompt Guide

Examples that replicate the old StyleGAN-Human attribute editing and style mixing capabilities.

---

## Attribute Editing

### Upper body length

```
full body portrait, wearing a crop top, standing, photorealistic
full body portrait, wearing a long sleeve shirt, standing, photorealistic
full body portrait, wearing a sleeveless top, standing, photorealistic
```

### Bottom body length

```
full body portrait, wearing short shorts, standing, photorealistic
full body portrait, wearing knee-length skirt, standing, photorealistic
full body portrait, wearing full-length trousers, standing, photorealistic
full body portrait, wearing a maxi dress, standing, photorealistic
```

---

## Style Mixing

```
full body portrait, casual streetwear, jeans and hoodie, standing, photorealistic
full body portrait, wearing a tailored business suit, standing, professional photo
full body portrait, athletic wear, gym outfit, standing, photorealistic
full body portrait, urban streetwear, sneakers, standing, photorealistic
```

---

## Unconditional Generation

```
full body portrait of a person, standing, photorealistic, high quality, studio lighting
```

---

## Tips

- Always include `standing` and `photorealistic` — they anchor the body pose and realism
- Add `studio lighting` or `outdoor` for environment control
- Add `full body` explicitly to avoid cropped results
- The more specific the clothing description, the better the result
