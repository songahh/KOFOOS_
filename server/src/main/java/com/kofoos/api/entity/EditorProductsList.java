package com.kofoos.api.entity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Getter
@Table(name = "editor_products_list")
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class EditorProductsList {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id")
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id")
    private EditorRecommendationArticle editorRecommendationArticle;

    @Builder
    public EditorProductsList(Product product, EditorRecommendationArticle editorRecommendationArticle) {
        setProduct(product);
        setEditorRecommendationArticle(editorRecommendationArticle);
    }

    private void setProduct(Product product){
        this.product = product;
        product.getEditorProductsLists().add(this);
    }

    private void setEditorRecommendationArticle(EditorRecommendationArticle article){
        this.editorRecommendationArticle = article;
        article.getEditorProductsList().add(this);
    }

}