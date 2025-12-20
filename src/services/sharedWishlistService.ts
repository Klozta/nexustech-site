/**
 * Service Wishlist Partagée / Listes de Cadeaux
 * Permet aux utilisateurs de créer des listes partageables avec réservation d'items
 */

import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../config/supabase.js';
import { handleServiceError } from '../utils/errorHandlers.js';
import { logger } from '../utils/logger.js';

export interface Wishlist {
  id: string;
  userId: string;
  name: string;
  description?: string;
  type: 'personal' | 'gift' | 'wedding' | 'birthday' | 'anniversary' | 'custom';
  isPublic: boolean;
  shareToken: string; // Token unique pour partage
  shareUrl?: string;
  eventDate?: string; // Date de l'événement (mariage, anniversaire, etc.)
  items: WishlistItem[];
  createdAt: string;
  updatedAt: string;
  totalItems: number;
  reservedItems: number;
  purchasedItems: number;
}

export interface WishlistItem {
  id: string;
  wishlistId: string;
  productId: string;
  productTitle?: string;
  productPrice?: number;
  productImage?: string;
  quantity: number;
  priority: 'low' | 'medium' | 'high';
  notes?: string;
  reservedBy?: string; // userId qui a réservé
  reservedAt?: string;
  purchasedBy?: string; // userId qui a acheté
  purchasedAt?: string;
  createdAt: string;
}

export interface WishlistShare {
  wishlistId: string;
  shareToken: string;
  accessCount: number;
  lastAccessedAt?: string;
}

/**
 * Service Wishlist Partagée
 */
export class SharedWishlistService {
  /**
   * Crée une nouvelle wishlist
   */
  async createWishlist(
    userId: string,
    data: {
      name: string;
      description?: string;
      type: Wishlist['type'];
      isPublic: boolean;
      eventDate?: string;
    }
  ): Promise<Wishlist> {
    try {
      const shareToken = this.generateShareToken();
      const wishlistId = uuidv4();

      const { data: wishlist, error } = await supabase
        .from('shared_wishlists')
        .insert({
          id: wishlistId,
          user_id: userId,
          name: data.name,
          description: data.description || null,
          type: data.type,
          is_public: data.isPublic,
          share_token: shareToken,
          event_date: data.eventDate || null,
        })
        .select()
        .single();

      if (error) {
        throw error;
      }

      // Retourner un Wishlist complet avec items vides (sera rempli si nécessaire)
      const mapped = this.mapWishlist(wishlist);
      return {
        ...mapped,
        items: [],
        totalItems: 0,
        reservedItems: 0,
        purchasedItems: 0,
      };
    } catch (error) {
      throw handleServiceError(error, 'createWishlist', 'Erreur création wishlist');
    }
  }

  /**
   * Récupère une wishlist par ID ou token de partage
   */
  async getWishlist(identifier: string, userId?: string): Promise<Wishlist | null> {
    try {
      let query = supabase.from('shared_wishlists').select('*');

      // Si c'est un UUID, chercher par ID
      if (identifier.match(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)) {
        query = query.eq('id', identifier);
      } else {
        // Sinon, chercher par share_token
        query = query.eq('share_token', identifier);
      }

      const { data: wishlist, error } = await query.single();

      if (error || !wishlist) {
        return null;
      }

      // Vérifier les permissions
      if (!wishlist.is_public && wishlist.user_id !== userId) {
        return null;
      }

      // Incrémenter le compteur d'accès si accès via token
      if (wishlist.share_token === identifier && wishlist.user_id !== userId) {
        await this.incrementAccessCount(wishlist.id);
      }

      // Récupérer les items
      const items = await this.getWishlistItems(wishlist.id);

      return {
        ...this.mapWishlist(wishlist),
        items,
        totalItems: items.length,
        reservedItems: items.filter((i) => i.reservedBy && !i.purchasedBy).length,
        purchasedItems: items.filter((i) => i.purchasedBy).length,
      };
    } catch (error) {
      throw handleServiceError(error, 'getWishlist', 'Erreur récupération wishlist');
    }
  }

  /**
   * Récupère les wishlists d'un utilisateur
   */
  async getUserWishlists(userId: string): Promise<Wishlist[]> {
    try {
      const { data, error } = await supabase
        .from('shared_wishlists')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        throw error;
      }

      const wishlists = await Promise.all(
        (data || []).map(async (w: any) => {
          const items = await this.getWishlistItems(w.id);
          const mapped = this.mapWishlist(w);
          return {
            ...mapped,
            items,
            totalItems: items.length,
            reservedItems: items.filter((i: WishlistItem) => i.reservedBy && !i.purchasedBy).length,
            purchasedItems: items.filter((i: WishlistItem) => i.purchasedBy).length,
          };
        })
      );

      return wishlists;
    } catch (error) {
      throw handleServiceError(error, 'getUserWishlists', 'Erreur récupération wishlists');
    }
  }

  /**
   * Ajoute un produit à une wishlist
   */
  async addItemToWishlist(
    wishlistId: string,
    productId: string,
    data: {
      quantity?: number;
      priority?: 'low' | 'medium' | 'high';
      notes?: string;
    }
  ): Promise<WishlistItem> {
    try {
      // Récupérer les infos du produit
      const { data: product, error: productError } = await supabase
        .from('products')
        .select('id, title, price, images')
        .eq('id', productId)
        .single();

      if (productError || !product) {
        throw new Error('Produit non trouvé');
      }

      const itemId = uuidv4();
      const { data: item, error } = await supabase
        .from('shared_wishlist_items')
        .insert({
          id: itemId,
          wishlist_id: wishlistId,
          product_id: productId,
          product_title: product.title,
          product_price: product.price,
          product_image: Array.isArray(product.images) ? product.images[0] : product.images,
          quantity: data.quantity || 1,
          priority: data.priority || 'medium',
          notes: data.notes || null,
        })
        .select()
        .single();

      if (error) {
        throw error;
      }

      return this.mapWishlistItem(item);
    } catch (error) {
      throw handleServiceError(error, 'addItemToWishlist', 'Erreur ajout item');
    }
  }

  /**
   * Réserve un item (pour éviter les doublons)
   */
  async reserveItem(itemId: string, userId: string): Promise<WishlistItem> {
    try {
      // Vérifier que l'item n'est pas déjà réservé ou acheté
      const { data: item, error: fetchError } = await supabase
        .from('shared_wishlist_items')
        .select('*')
        .eq('id', itemId)
        .single();

      if (fetchError || !item) {
        throw new Error('Item non trouvé');
      }

      if (item.reserved_by && item.reserved_by !== userId) {
        throw new Error('Item déjà réservé par quelqu\'un d\'autre');
      }

      if (item.purchased_by) {
        throw new Error('Item déjà acheté');
      }

      // Réserver l'item
      const { data: updated, error } = await supabase
        .from('shared_wishlist_items')
        .update({
          reserved_by: userId,
          reserved_at: new Date().toISOString(),
        })
        .eq('id', itemId)
        .select()
        .single();

      if (error) {
        throw error;
      }

      // Notifier le propriétaire de la wishlist
      await this.notifyOwnerReservation(item.wishlist_id, itemId, userId);

      return this.mapWishlistItem(updated);
    } catch (error) {
      throw handleServiceError(error, 'reserveItem', 'Erreur réservation item');
    }
  }

  /**
   * Marque un item comme acheté
   */
  async markItemAsPurchased(itemId: string, userId: string): Promise<WishlistItem> {
    try {
      const { data: item, error: fetchError } = await supabase
        .from('shared_wishlist_items')
        .select('*')
        .eq('id', itemId)
        .single();

      if (fetchError || !item) {
        throw new Error('Item non trouvé');
      }

      // Marquer comme acheté
      const { data: updated, error } = await supabase
        .from('shared_wishlist_items')
        .update({
          purchased_by: userId,
          purchased_at: new Date().toISOString(),
          reserved_by: userId, // S'assurer que c'est réservé aussi
          reserved_at: new Date().toISOString(),
        })
        .eq('id', itemId)
        .select()
        .single();

      if (error) {
        throw error;
      }

      // Notifier le propriétaire
      await this.notifyOwnerPurchase(item.wishlist_id, itemId, userId);

      return this.mapWishlistItem(updated);
    } catch (error) {
      throw handleServiceError(error, 'markItemAsPurchased', 'Erreur marquage achat');
    }
  }

  /**
   * Annule une réservation
   */
  async cancelReservation(itemId: string, userId: string): Promise<void> {
    try {
      const { data: item } = await supabase
        .from('shared_wishlist_items')
        .select('reserved_by')
        .eq('id', itemId)
        .single();

      if (item?.reserved_by !== userId) {
        throw new Error('Vous ne pouvez pas annuler cette réservation');
      }

      await supabase
        .from('shared_wishlist_items')
        .update({
          reserved_by: null,
          reserved_at: null,
        })
        .eq('id', itemId);
    } catch (error) {
      throw handleServiceError(error, 'cancelReservation', 'Erreur annulation réservation');
    }
  }

  /**
   * Supprime un item d'une wishlist
   */
  async removeItemFromWishlist(itemId: string, wishlistId: string, userId: string): Promise<void> {
    try {
      // Vérifier que l'utilisateur est propriétaire de la wishlist
      const { data: wishlist } = await supabase
        .from('shared_wishlists')
        .select('user_id')
        .eq('id', wishlistId)
        .single();

      if (wishlist?.user_id !== userId) {
        throw new Error('Vous n\'êtes pas propriétaire de cette wishlist');
      }

      await supabase.from('shared_wishlist_items').delete().eq('id', itemId).eq('wishlist_id', wishlistId);
    } catch (error) {
      throw handleServiceError(error, 'removeItemFromWishlist', 'Erreur suppression item');
    }
  }

  /**
   * Génère un token de partage unique
   */
  private generateShareToken(): string {
    return Buffer.from(uuidv4() + Date.now().toString()).toString('base64url').substring(0, 32);
  }

  /**
   * Incrémente le compteur d'accès
   */
  private async incrementAccessCount(wishlistId: string): Promise<void> {
    await supabase.rpc('increment_wishlist_access', { p_wishlist_id: wishlistId }).catch(() => {
      // Ignorer si la fonction n'existe pas encore
    });
  }

  /**
   * Notifie le propriétaire d'une réservation
   */
  private async notifyOwnerReservation(wishlistId: string, itemId: string, userId: string): Promise<void> {
    const { data: wishlist } = await supabase
      .from('shared_wishlists')
      .select('user_id, name')
      .eq('id', wishlistId)
      .single();

    if (wishlist && wishlist.user_id !== userId) {
      // TODO: Envoyer notification email/push
      logger.info('Item réservé', { wishlistId, itemId, reservedBy: userId, owner: wishlist.user_id });
    }
  }

  /**
   * Notifie le propriétaire d'un achat
   */
  private async notifyOwnerPurchase(wishlistId: string, itemId: string, userId: string): Promise<void> {
    const { data: wishlist } = await supabase
      .from('shared_wishlists')
      .select('user_id, name')
      .eq('id', wishlistId)
      .single();

    if (wishlist && wishlist.user_id !== userId) {
      // TODO: Envoyer notification email/push
      logger.info('Item acheté', { wishlistId, itemId, purchasedBy: userId, owner: wishlist.user_id });
    }
  }

  /**
   * Récupère les items d'une wishlist
   */
  private async getWishlistItems(wishlistId: string): Promise<WishlistItem[]> {
    const { data, error } = await supabase
      .from('shared_wishlist_items')
      .select('*')
      .eq('wishlist_id', wishlistId)
      .order('priority', { ascending: false })
      .order('created_at', { ascending: true });

    if (error) {
      logger.warn('Erreur récupération items', { error, wishlistId });
      return [];
    }

    return (data || []).map((item: any) => this.mapWishlistItem(item));
  }

  // Helpers
  private mapWishlist(data: any): Omit<Wishlist, 'items' | 'totalItems' | 'reservedItems' | 'purchasedItems'> {
    return {
      id: data.id,
      userId: data.user_id,
      name: data.name,
      description: data.description,
      type: data.type,
      isPublic: data.is_public,
      shareToken: data.share_token,
      shareUrl: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/wishlist/${data.share_token}`,
      eventDate: data.event_date,
      createdAt: data.created_at,
      updatedAt: data.updated_at,
    };
  }

  private mapWishlistItem(data: any): WishlistItem {
    return {
      id: data.id,
      wishlistId: data.wishlist_id,
      productId: data.product_id,
      productTitle: data.product_title,
      productPrice: data.product_price,
      productImage: data.product_image,
      quantity: data.quantity,
      priority: data.priority,
      notes: data.notes,
      reservedBy: data.reserved_by,
      reservedAt: data.reserved_at,
      purchasedBy: data.purchased_by,
      purchasedAt: data.purchased_at,
      createdAt: data.created_at,
    };
  }
}

// Instance singleton
export const sharedWishlistService = new SharedWishlistService();

