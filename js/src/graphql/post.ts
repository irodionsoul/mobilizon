import gql from "graphql-tag";
import { TAG_FRAGMENT } from "./tags";

export const POST_FRAGMENT = gql`
  fragment PostFragment on Post {
    id
    title
    slug
    url
    body
    author {
      id
      preferredUsername
      name
      domain
      avatar {
        url
      }
    }
    attributedTo {
      id
      preferredUsername
      name
      domain
      avatar {
        url
      }
    }
    insertedAt
    updatedAt
    publishAt
    draft
    visibility
    tags {
      ...TagFragment
    }
  }
  ${TAG_FRAGMENT}
`;

export const POST_BASIC_FIELDS = gql`
  fragment PostBasicFields on Post {
    id
    title
    slug
    url
    author {
      id
      preferredUsername
      name
      avatar {
        url
      }
    }
    attributedTo {
      id
      preferredUsername
      name
      avatar {
        url
      }
    }
    insertedAt
    updatedAt
    publishAt
    draft
  }
`;

export const FETCH_GROUP_POSTS = gql`
  query GroupPosts($preferredUsername: String!, $page: Int, $limit: Int) {
    group(preferredUsername: $preferredUsername) {
      id
      preferredUsername
      domain
      name
      posts(page: $page, limit: $limit) {
        total
        elements {
          ...PostBasicFields
        }
      }
    }
  }
  ${POST_BASIC_FIELDS}
`;

export const FETCH_POST = gql`
  query Post($slug: String!) {
    post(slug: $slug) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const CREATE_POST = gql`
  mutation CreatePost(
    $title: String!
    $body: String
    $attributedToId: ID!
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
  ) {
    createPost(
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const UPDATE_POST = gql`
  mutation UpdatePost(
    $id: ID!
    $title: String
    $body: String
    $attributedToId: ID
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
  ) {
    updatePost(
      id: $id
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const DELETE_POST = gql`
  mutation DeletePost($id: ID!) {
    deletePost(id: $id) {
      id
    }
  }
`;
