import assert from "node:assert/strict";
import test from "node:test";
import { makeFixtureRecipe } from "../src/avatar-recipe-fixture.js";
import { validateAvatarRecipe } from "../src/avatar-recipe-validator.js";

test("fixture recipe matches the schema contract", () => {
  const result = validateAvatarRecipe(makeFixtureRecipe());
  assert.equal(result.valid, true, result.errors.join("; "));
});

test("validator rejects out-of-range normalized fields and extra properties", () => {
  const recipe = makeFixtureRecipe();
  recipe.face.roundness = 2;
  recipe.skin.extra = "nope";

  const result = validateAvatarRecipe(recipe);

  assert.equal(result.valid, false);
  assert.match(result.errors.join("; "), /face.roundness/);
  assert.match(result.errors.join("; "), /skin.extra/);
});
