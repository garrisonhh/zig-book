<?php

/**
 * Tony's php recipe book.
 *
 * Expects the library to be built already. Must be run with `-c php.ini` (it
 * just enables ffi). Also expects some environment variables to be set (see
 * directly below this comment).
 *
 * I have never written php in my life, this is terrible code and I apologize. I
 * knew it would be absolute gibberish, but I also figure that Tony would be
 * writing trash code too, no?
 *
 * It was fun though, php has a very different mental model of how web apps should
 * work than SPAs which were my first introduction to the web. Maybe I'll invest
 * more time into php, especially for static web projects.
 **/

$RECIPE_LIB_PATH = $_ENV['RECIPE_SO'] ?? "../zig-out/lib/librecipe-book.so";
$RECIPE_BOOK_PATH = $_ENV['RECIPE_BOOK_PATH'] ?? "recipes.json";

function loadFfi() {
    global $RECIPE_LIB_PATH;

    $cdef = <<<CDEF
        typedef struct RecipeBook RecipeBook;

        typedef struct RetrievedIngredient {
            const char *quantity;
            const char *name;
        } RetrievedIngredient;

        typedef struct RetrievedRecipe {
            const char *name;
            const char *author;
            const char *instructions;
            const RetrievedIngredient *const ingredients;
            size_t ingredient_count;
        } RetrievedRecipe;

        typedef struct RecipeBookIterator {
            const RecipeBook *book;
            int next_id;
        } RecipeBookIterator;

        void recipes_quit(void);

        RecipeBook *recipe_book_create(void);
        void recipe_book_close(RecipeBook *book);
        int recipe_book_save(RecipeBook *book, const char *filename);
        RecipeBook *recipe_book_load(const char *filename);

        int recipe_create(RecipeBook *book, const char *name, const char *author,
                const char *instructions, int *out_id);
        void recipe_delete(RecipeBook *book, int recipe_id);
        int recipe_add_ingredient(RecipeBook *book, int recipe_id, const char *qty,
                const char *name);
        int recipe_get(RecipeBook *book, int recipe_id, char *buf, size_t bufsz,
                RetrievedRecipe *out_recipe);

        void recipe_iter_start(const RecipeBook *book, RecipeBookIterator *iter);
        bool recipe_iter_next(RecipeBookIterator *iter, int *next_id);
    CDEF;
    return FFI::cdef($cdef, $RECIPE_LIB_PATH);
}

function loadBook($ffi) {
    global $RECIPE_BOOK_PATH;

    if (file_exists($RECIPE_BOOK_PATH)) {
        return $ffi->recipe_book_load($RECIPE_BOOK_PATH);
    }
    return $ffi->recipe_book_create();
}

function jsonResponse($data, $status = 200) {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store, no-cache, must-revalidate');
    header('Pragma: no-cache');

    echo json_encode($data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}


function htmlResponse($html, $status = 200) {
    http_response_code($status);
    header('Content-Type: text/html; charset=utf-8');

    echo $html;
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$route = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$route = trim($route, '/');

if ($method === 'GET' && $route === 'recipes') {
    global $RECIPE_BOOK_PATH;

    $ffi = loadFfi();
    $book = loadBook($ffi);

    $json_recipes = [];

    $recipe_iter = $ffi->new("RecipeBookIterator");
    $ffi->recipe_iter_start($book, FFI::addr($recipe_iter));

    $recipe_bufsz = 4096;
    $recipe_buf = $ffi->new("char[$recipe_bufsz]");
    $recipe_id = $ffi->new("int");
    while ($ffi->recipe_iter_next(FFI::addr($recipe_iter), FFI::addr($recipe_id))) {
        $recipe = $ffi->new("RetrievedRecipe");
        $res = $ffi->recipe_get($book, $recipe_id->cdata, $recipe_buf, $recipe_bufsz, FFI::addr($recipe));

        if ($res != 0) {
            jsonResponse(["error" => $res], 400);
        }

        $json_ingredients = [];
        for ($i = 0; $i < $recipe->ingredient_count; $i++) {
            $ingredient = $recipe->ingredients[$i];
            array_push($json_ingredients, [
                "quantity" => $ingredient->quantity,
                "name" => $ingredient->name,
            ]);
        }

        array_push($json_recipes, [
            "id" => $recipe_id->cdata,
            "name" => $recipe->name,
            "author" => $recipe->author,
            "instructions" => $recipe->instructions,
            "ingredients" => $json_ingredients,
        ]);
    }

    $save_res = $ffi->recipe_book_save($book, $RECIPE_BOOK_PATH);
    $ffi->recipe_book_close($book);
    $ffi->recipes_quit();

    jsonResponse($json_recipes);
} elseif ($method === 'POST' && $route === 'create') {
    global $RECIPE_BOOK_PATH;

    $data = json_decode(file_get_contents('php://input'), true);

    $ffi = loadFfi();
    $book = loadBook($ffi);

    $recipe_id = $ffi->new("int");
    $ffi->recipe_create($book, $data['name'], $data['author'], $data['instructions'], FFI::addr($recipe_id));

    foreach ($data['ingredients'] as ["quantity" => $quantity, "name" => $name]) {
        $ffi->recipe_add_ingredient($book, $recipe_id->cdata, $quantity, $name);
    }

    $save_res = $ffi->recipe_book_save($book, $RECIPE_BOOK_PATH);
    $ffi->recipe_book_close($book);
    $ffi->recipes_quit();

    jsonResponse("");
}

// no api method, so return the page
htmlResponse(<<<'HTML'

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
    <title>PHP - Hello, World!</title>
</head>

<style>
#ingredients-table input[type="text"] {
    width: 100%;
}

label {
    font-weight: bold;
}

#ingredients-table {
    border-radius: 3px;
    margin: 0;
    margin-bottom: 5px;
}

#ingredients-table>tbody td {
    padding: 0;
    height: min-content;
}

#ingredients-table>tbody td>* {
    width: 100%;
    margin: 0;
}

h3 {
    margin: 0px;
}

body>div {
    border: 2px solid;
    border-radius: 5px;
    padding: 10px;
    margin-bottom: 10px;
}

.recipe {
    border: 1px solid;
    border-radius: 5px;
    padding: 10px;
    margin: 10px;
}

.recipe>* {
    margin: 5px;
}
</style>

<body>
    <h1>David's Recipe Book</h1>

    <div id="recipes">
        <h3>Recipes</h3>
        <div id="recipe-list">
            No recipes yet!
        </div>
    </div>

    <div id="add-recipe-form">
        <h3>Create a Recipe</h2>
        <div style="display: flex; flex-direction: row; justify-content: flex-end; gap: 10px">
            <div id="name-wrapper" style="flex-grow: 2">
                <label for="recipe-name">Name</label>
                <input id="recipe-name" name="recipe-name" type="text" style="width: 100%">
            </div>
            <div id="author-wrapper">
                <label for="recipe-author">Created by</label>
                <input id="recipe-author" name="recipe-author" type="text">
            </div>
        </div>
        <div id="ingredients">
            <label for="ingredients-table">Ingredients</label>
            <table id="ingredients-table" name="ingredients-table" style="width: 100%">
                <thead>
                    <tr>
                        <td style="width: 0">Delete</td>
                        <td style="width: 20%">Quantity</td>
                        <td>Name</td>
                    <tr>
                </thead>
                <tbody id="ingredients-body"></tbody>
            </table>
            <button id="add-ingredient">Add ingredient</button>
        </div>
        <label for="recipe-instructions">Instructions</label>
        <textarea id="recipe-instructions" name="recipe-instructions" rows=10></textarea>
        <button id="add-recipe-btn">Create recipe!</button>
    </div>
</body>

<script>

async function updateRecipeList() {
    const recipes = await fetch('/recipes')
        .then((res) => res.json());

    const updatedRecipes = [];
    for (const recipe of recipes) {
        const recipeTitle = document.createElement('h4');
        recipeTitle.textContent = recipe.name;

        const recipeAuthor = document.createElement('p');
        recipeAuthor.textContent = `by ${recipe.author}`;

        const ingredientList = document.createElement('ul');
        for (const {quantity, name} of recipe.ingredients) {
            const ingredientLi = document.createElement('li');
            ingredientLi.textContent = `${quantity} of ${name}`;
            ingredientList.appendChild(ingredientLi);
        }

        const instructionP = document.createElement('p');
        instructionP.innerText = recipe.instructions;

        const recipeWrapper = document.createElement('div');
        recipeWrapper.classList.add('recipe');
        recipeWrapper.replaceChildren(
            recipeTitle,
            recipeAuthor,
            ingredientList,
            instructionP,
        );

        updatedRecipes.push(recipeWrapper);
    }

    document.querySelector('#recipe-list').replaceChildren(...updatedRecipes);
}

addEventListener('load', updateRecipeList);

document.querySelector('#add-ingredient').addEventListener('click', () => {
    const row = document.createElement('tr');

    const deleteBtn = document.createElement('button');
    deleteBtn.addEventListener('click', () => row.remove());
    deleteBtn.innerText = "❌";

    const deleteTd = document.createElement('td');
    deleteTd.appendChild(deleteBtn);
    row.appendChild(deleteTd);

    for (const kind of ["quantity", "name"]) {
        const textInput = document.createElement('input');
        textInput['type'] = 'text';


        console.log(document.querySelector('#ingredients-body').children);
        const inputTd = document.createElement('td');
        inputTd.appendChild(textInput);
        row.appendChild(inputTd);
    }

    document.querySelector('#ingredients-body').appendChild(row);
});

document.querySelector('#add-recipe-btn').addEventListener('click', async () => {
    const name = document.querySelector('#recipe-name').value;
    const author = document.querySelector('#recipe-author').value;
    const instructions = document.querySelector('#recipe-instructions').value;

    console.log(document.querySelector('#ingredients-body').children);

    const ingredients =
        Array.from(document.querySelector('#ingredients-body').children)
        .map((row) => ({
            quantity: row.children[1].firstChild.value,
            name: row.children[2].firstChild.value,
        }));

    const recipe = { name, author, instructions, ingredients };

    await fetch('/create', {
        method: 'POST',
        body: JSON.stringify(recipe),
    });
    await updateRecipeList();
});
</script>
</html>

HTML);
?>
