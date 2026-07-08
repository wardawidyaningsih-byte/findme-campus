<?php

namespace App\Http\Controllers;

use App\Models\Item;
use App\Models\Claim;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;

class ItemController extends Controller
{
    public function index(Request $request)
    {
        $query = Item::with('user')->where('status', '!=', 'returned');

        // Search by name
        if ($request->has('search') && !empty($request->search)) {
            $query->where('name', 'like', '%' . $request->search . '%');
        }

        // Filter by type (lost / found)
        if ($request->has('type') && !empty($request->type)) {
            $query->where('type', $request->type);
        }

        // Filter by category
        if ($request->has('category') && !empty($request->category)) {
            $query->where('category', $request->category);
        }

        // Filter by location
        if ($request->has('location') && !empty($request->location)) {
            $query->where('location', $request->location);
        }

        // Filter by date
        if ($request->has('date') && !empty($request->date)) {
            $query->whereDate('date', $request->date);
        }

        // Filter by status
        if ($request->has('status') && !empty($request->status)) {
            $query->where('status', $request->status);
        }

        $items = $query->orderBy('created_at', 'desc')->get();

        // Enforce privacy: strip phone numbers in listings
        $items->each(function ($item) {
            if ($item->user) {
                $item->user->makeHidden('phone_number');
            }
        });

        return response()->json($items);
    }

    public function history(Request $request)
    {
        $items = Item::with('user')
            ->where('status', 'returned')
            ->orderBy('updated_at', 'desc')
            ->get();

        // Strip phone numbers for history lists
        $items->each(function ($item) {
            if ($item->user) {
                $item->user->makeHidden('phone_number');
            }
        });

        return response()->json($items);
    }

    public function show(Request $request, $id)
    {
        $item = Item::with('user')->find($id);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        // Privacy check for WhatsApp number (phone_number)
        $revealPhone = false;
        
        // Check if user is authenticated via Sanctum
        $user = Auth::guard('sanctum')->user();
        if ($user) {
            // Finder is the owner of the report
            if ($user->id === $item->user_id) {
                $revealPhone = true;
            } else {
                // Claimant has an approved claim for this item
                $hasApprovedClaim = Claim::where('item_id', $item->id)
                    ->where('claimant_id', $user->id)
                    ->where('status', 'approved')
                    ->exists();
                if ($hasApprovedClaim) {
                    $revealPhone = true;
                }
            }
        }

        if (!$revealPhone && $item->user) {
            $item->user->makeHidden('phone_number');
        }

        return response()->json($item);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        $rules = [
            'type' => 'required|in:lost,found',
            'name' => 'required|string|max:255',
            'category' => 'required|string',
            'location' => 'required|string',
            'date' => 'required|date',
            'description' => 'required|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ];

        // Found items require a verification question
        if ($request->input('type') === 'found') {
            $rules['verification_question'] = 'required|string';
            $rules['custodian_type'] = 'nullable|in:security,lab_assistant';
            $rules['custodian_name'] = 'required_with:custodian_type|nullable|string|max:255';
        }

        $validated = $request->validate($rules);

        // Upload image
        $imagePath = null;
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('items', 'public');
            $imagePath = 'storage/' . $path;
        }

        // Set status
        $status = 'lost';
        if ($validated['type'] === 'found') {
            if (!empty($request->input('custodian_type'))) {
                $status = $request->input('custodian_type'); // 'security' or 'lab_assistant'
            } else {
                $status = 'found';
            }
        }

        $item = Item::create([
            'user_id' => $user->id,
            'type' => $validated['type'],
            'image_path' => $imagePath,
            'name' => $validated['name'],
            'category' => $validated['category'],
            'location' => $validated['location'],
            'date' => $validated['date'],
            'description' => $validated['description'],
            'status' => $status,
            'verification_question' => $request->input('verification_question'),
            'custodian_type' => $request->input('custodian_type'),
            'custodian_name' => $request->input('custodian_name'),
        ]);

        return response()->json([
            'message' => 'Item reported successfully',
            'item' => $item
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $item = Item::find($id);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        if ($item->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $rules = [
            'name' => 'sometimes|required|string|max:255',
            'category' => 'sometimes|required|string',
            'location' => 'sometimes|required|string',
            'date' => 'sometimes|required|date',
            'description' => 'sometimes|required|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'status' => 'sometimes|required|in:lost,found,security,lab_assistant,returned',
        ];

        if ($item->type === 'found') {
            $rules['verification_question'] = 'sometimes|required|string';
            $rules['custodian_type'] = 'nullable|in:security,lab_assistant';
            $rules['custodian_name'] = 'required_with:custodian_type|nullable|string|max:255';
        }

        $validated = $request->validate($rules);

        // Upload image if updated
        if ($request->hasFile('image')) {
            // Delete old image
            if ($item->image_path) {
                $oldPath = str_replace('storage/', '', $item->image_path);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('image')->store('items', 'public');
            $item->image_path = 'storage/' . $path;
        }

        // Set status and custodian fields
        if ($request->has('status')) {
            $item->status = $request->status;
        }

        if ($item->type === 'found') {
            if ($request->has('verification_question')) {
                $item->verification_question = $request->verification_question;
            }
            if ($request->has('custodian_type')) {
                $item->custodian_type = $request->custodian_type;
                if (empty($request->custodian_type) && $item->status !== 'returned') {
                    $item->status = 'found';
                } else if ($item->status !== 'returned') {
                    $item->status = $request->custodian_type;
                }
            }
            if ($request->has('custodian_name')) {
                $item->custodian_name = $request->custodian_name;
            }
        }

        $item->fill($request->only(['name', 'category', 'location', 'date', 'description']));
        $item->save();

        return response()->json([
            'message' => 'Item updated successfully',
            'item' => $item
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $item = Item::find($id);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        if ($item->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($item->image_path) {
            $oldPath = str_replace('storage/', '', $item->image_path);
            Storage::disk('public')->delete($oldPath);
        }

        $item->delete();

        return response()->json([
            'message' => 'Item deleted successfully'
        ]);
    }

    public function myItems(Request $request)
    {
        $items = Item::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($items);
    }
}
