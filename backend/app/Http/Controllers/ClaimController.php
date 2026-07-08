<?php

namespace App\Http\Controllers;

use App\Models\Claim;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ClaimController extends Controller
{
    public function store(Request $request, $itemId)
    {
        $user = $request->user();
        $item = Item::find($itemId);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        if ($item->user_id === $user->id) {
            return response()->json(['message' => 'You cannot claim your own reported item'], 400);
        }

        if ($item->status === 'returned') {
            return response()->json(['message' => 'This item has already been returned'], 400);
        }

        $validated = $request->validate([
            'verification_answer' => 'required|string',
        ]);

        // Check for existing claim
        $existingClaim = Claim::where('item_id', $item->id)
            ->where('claimant_id', $user->id)
            ->first();

        if ($existingClaim) {
            return response()->json(['message' => 'You have already submitted a claim for this item'], 400);
        }

        $claim = Claim::create([
            'item_id' => $item->id,
            'claimant_id' => $user->id,
            'verification_answer' => $validated['verification_answer'],
            'status' => 'pending',
        ]);

        return response()->json([
            'message' => 'Claim submitted successfully',
            'claim' => $claim
        ], 201);
    }

    public function myClaims(Request $request)
    {
        $user = $request->user();
        $claims = Claim::with(['item.user', 'item' => function ($query) {
            $query->withCount('claims');
        }])
        ->where('claimant_id', $user->id)
        ->orderBy('created_at', 'desc')
        ->get();

        // Mask phone number of reporter unless the claim is approved
        $claims->each(function ($claim) {
            if ($claim->item && $claim->item->user) {
                if ($claim->status !== 'approved') {
                    $claim->item->user->makeHidden('phone_number');
                }
            }
        });

        return response()->json($claims);
    }

    public function itemClaims(Request $request, $itemId)
    {
        $user = $request->user();
        $item = Item::find($itemId);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        if ($item->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $claims = Claim::with('claimant')
            ->where('item_id', $item->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($claims);
    }

    public function updateStatus(Request $request, $id)
    {
        $user = $request->user();
        $claim = Claim::with('item')->find($id);

        if (!$claim) {
            return response()->json(['message' => 'Claim not found'], 404);
        }

        if ($claim->item->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $validated = $request->validate([
            'status' => 'required|in:approved,rejected',
        ]);

        if ($claim->status !== 'pending') {
            return response()->json(['message' => 'This claim has already been processed'], 400);
        }

        if ($validated['status'] === 'approved') {
            $claim->status = 'approved';
            $claim->save();

            // Set item status to returned (Commented out to allow manual completion by finder)
            // $item = $claim->item;
            // $item->status = 'returned';
            // $item->save();

            // Reject all other pending claims for this item
            Claim::where('item_id', $claim->item_id)
                ->where('id', '!=', $claim->id)
                ->where('status', 'pending')
                ->update(['status' => 'rejected']);
        } else {
            $claim->status = 'rejected';
            $claim->save();
        }

        return response()->json([
            'message' => 'Claim status updated successfully',
            'claim' => $claim
        ]);
    }
}
